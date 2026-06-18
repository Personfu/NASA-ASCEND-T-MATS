"""
Latex sounding-balloon ascent and burst prediction.

Physics
-------
A free latex balloon ascends because of net buoyancy. At a quasi-steady ascent
the buoyant free-lift force is balanced by aerodynamic drag on the (roughly
spherical) envelope:

    F_free = 1/2 * rho_air * Cd * A * w^2

=> ascent velocity   w = sqrt( 2 * F_free / (rho_air * Cd * A) )

where A = pi/4 * D^2 is the balloon frontal area and Cd ~ 0.25-0.30 for a
buoyant sphere in the relevant Reynolds-number range (Gallice et al. 2011 use
a Reynolds-dependent Cd; we expose Cd as a parameter and default to 0.25).

As the balloon rises, ambient pressure falls, the (unpressurized) envelope
expands, the diameter and drag area grow, and the gas density falls. Burst
occurs when the envelope diameter reaches the manufacturer's published burst
diameter. We integrate the ascent in altitude steps, updating volume from the
ideal-gas law at ambient P,T.

References
----------
* Gallice, A., et al. (2011), "Modeling the ascent of sounding balloons:
  derivation of the vertical air motion," Atmos. Meas. Tech., 4, 2235-2253.
* Kaymont / Totex sounding-balloon datasheets (burst diameter, nozzle lift,
  recommended free lift, mass).
* NOAA NWS Radiosonde Replacement System engineering reports.
"""

from __future__ import annotations

import math
from dataclasses import dataclass, field

from .constants import G_EARTH_STD, R_UNIVERSAL
from .atmosphere import atmosphere
from . import lift_gas

# Manufacturer burst-diameter & mass table (public datasheet values).
# model -> dict(mass_kg, burst_diameter_m, recommended_payload_kg)
# Kaymont/Totex/Hwoyee sounding balloons. Burst diameters are nominal.
BALLOON_CATALOG = {
    "Kaymont-200":  {"mass_kg": 0.200, "burst_diameter_m": 3.00, "nominal_burst_km": 22.0},
    "Kaymont-300":  {"mass_kg": 0.300, "burst_diameter_m": 3.78, "nominal_burst_km": 24.0},
    "Kaymont-600":  {"mass_kg": 0.600, "burst_diameter_m": 6.02, "nominal_burst_km": 30.0},
    "Kaymont-800":  {"mass_kg": 0.800, "burst_diameter_m": 7.00, "nominal_burst_km": 32.5},
    "Kaymont-1000": {"mass_kg": 1.000, "burst_diameter_m": 7.86, "nominal_burst_km": 33.0},
    "Kaymont-1200": {"mass_kg": 1.200, "burst_diameter_m": 8.63, "nominal_burst_km": 34.0},
    "Kaymont-1500": {"mass_kg": 1.500, "burst_diameter_m": 9.44, "nominal_burst_km": 35.0},
    "Kaymont-2000": {"mass_kg": 2.000, "burst_diameter_m": 10.54, "nominal_burst_km": 37.0},
    "Kaymont-3000": {"mass_kg": 3.000, "burst_diameter_m": 13.00, "nominal_burst_km": 38.0},
    "Totex-1200":   {"mass_kg": 1.200, "burst_diameter_m": 8.63, "nominal_burst_km": 34.0},
    "Totex-1500":   {"mass_kg": 1.500, "burst_diameter_m": 9.44, "nominal_burst_km": 35.0},
}


@dataclass
class AscentSample:
    t_s: float
    altitude_m: float
    pressure_Pa: float
    temperature_K: float
    gas_volume_m3: float
    diameter_m: float
    ascent_rate_mps: float
    free_lift_N: float


@dataclass
class AscentResult:
    samples: list = field(default_factory=list)
    burst_altitude_m: float = float("nan")
    burst_time_s: float = float("nan")
    burst_diameter_m: float = float("nan")
    mean_ascent_rate_mps: float = float("nan")
    gas: str = ""
    n_moles: float = 0.0

    @property
    def altitudes_m(self):
        return [s.altitude_m for s in self.samples]

    @property
    def times_s(self):
        return [s.t_s for s in self.samples]


def simulate_ascent(
    gas: str,
    payload_mass_kg: float,
    balloon_model: str = "Kaymont-1500",
    free_lift_kg: float = 1.0,
    Cd: float = 0.25,
    dz_m: float = 20.0,
    z0_m: float = 0.0,
    burst_diameter_m: float | None = None,
    balloon_mass_kg: float | None = None,
) -> AscentResult:
    """Integrate a free-balloon ascent until burst.

    Parameters
    ----------
    gas              : 'helium' or 'hydrogen'
    payload_mass_kg  : suspended train mass (payload + parachute + rigging)
    balloon_model    : key into BALLOON_CATALOG (sets mass + burst diameter)
    free_lift_kg     : free lift set at launch (kg-force)
    Cd               : envelope drag coefficient (sphere, ~0.25)
    dz_m             : altitude integration step
    z0_m             : launch geometric altitude
    """
    if balloon_model in BALLOON_CATALOG:
        spec = BALLOON_CATALOG[balloon_model]
        b_mass = spec["mass_kg"] if balloon_mass_kg is None else balloon_mass_kg
        b_burst = spec["burst_diameter_m"] if burst_diameter_m is None else burst_diameter_m
    else:
        if burst_diameter_m is None or balloon_mass_kg is None:
            raise ValueError("unknown balloon_model; supply burst_diameter_m and balloon_mass_kg")
        b_mass = balloon_mass_kg
        b_burst = burst_diameter_m

    # Solve for moles giving the requested free lift at launch.
    n = lift_gas.moles_for_free_lift(gas, free_lift_kg, payload_mass_kg, b_mass, z0_m)

    suspended = payload_mass_kg + b_mass  # dead mass lifted (balloon stays attached)
    result = AscentResult(gas=gas, n_moles=n)

    z = z0_m
    t = 0.0
    M = lift_gas.gas_molar_mass(gas)
    gas_mass = n * M

    while True:
        st = atmosphere(z)
        V = n * R_UNIVERSAL * st.temperature_K / st.pressure_Pa
        D = lift_gas.diameter_from_volume(V)
        rho_air = lift_gas.air_density(st.pressure_Pa, st.temperature_K)
        # net buoyant (free) force available to overcome drag:
        gross_N = (rho_air * V - gas_mass) * G_EARTH_STD
        free_N = gross_N - suspended * G_EARTH_STD
        A = math.pi / 4.0 * D ** 2
        if free_N <= 0.0:
            w = 0.0
        else:
            w = math.sqrt(2.0 * free_N / (rho_air * Cd * A))

        result.samples.append(AscentSample(
            t_s=t, altitude_m=z, pressure_Pa=st.pressure_Pa,
            temperature_K=st.temperature_K, gas_volume_m3=V, diameter_m=D,
            ascent_rate_mps=w, free_lift_N=free_N,
        ))

        if D >= b_burst:
            result.burst_altitude_m = z
            result.burst_time_s = t
            result.burst_diameter_m = D
            break
        if w <= 1e-3:
            # neutral buoyancy / float -- not a burst flight
            result.burst_altitude_m = z
            result.burst_time_s = t
            result.burst_diameter_m = D
            break
        if z > 60_000.0:
            break

        dt = dz_m / w
        z += dz_m
        t += dt

    if result.samples:
        rates = [s.ascent_rate_mps for s in result.samples if s.ascent_rate_mps > 0]
        result.mean_ascent_rate_mps = sum(rates) / len(rates) if rates else float("nan")
    return result
