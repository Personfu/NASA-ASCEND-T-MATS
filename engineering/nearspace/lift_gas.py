"""
Lift-gas thermodynamics and buoyancy for sounding balloons.

Handles helium and hydrogen fill gases. Buoyant lift follows Archimedes:
the net (gross) lift of a volume V of lift gas in ambient air is

    L_gross = (rho_air - rho_gas) * V * g

with rho computed from the ideal-gas law at the *ambient* pressure and
temperature (a free latex balloon is unpressurized, so internal pressure
tracks ambient until it becomes taut near burst).

References
----------
* NOAA/NWS Radiosonde Observation handbook (free-lift / nozzle-lift practice).
* Kaymont / Totex sounding-balloon technical data (burst diameters, payloads).
* NIST Chemistry WebBook (molar masses).
* Gallice et al., "Modeling the ascent of sounding balloons,"
  Atmos. Meas. Tech., 2011 (super-pressure-free latex balloon physics).
"""

from __future__ import annotations

from dataclasses import dataclass

from .constants import (
    R_UNIVERSAL,
    M_HELIUM,
    M_HYDROGEN,
    M_AIR,
    G_EARTH_STD,
)
from .atmosphere import atmosphere

_GAS_MOLAR_MASS = {
    "helium": M_HELIUM,
    "he": M_HELIUM,
    "hydrogen": M_HYDROGEN,
    "h2": M_HYDROGEN,
}


def gas_molar_mass(gas: str) -> float:
    key = gas.strip().lower()
    if key not in _GAS_MOLAR_MASS:
        raise ValueError(f"unknown lift gas '{gas}' (use 'helium' or 'hydrogen')")
    return _GAS_MOLAR_MASS[key]


def gas_density(gas: str, pressure_Pa: float, temperature_K: float) -> float:
    """Ideal-gas density of the lift gas (kg/m^3)."""
    M = gas_molar_mass(gas)
    return pressure_Pa * M / (R_UNIVERSAL * temperature_K)


def air_density(pressure_Pa: float, temperature_K: float) -> float:
    """Ideal-gas density of dry air (kg/m^3) at given P, T."""
    return pressure_Pa * M_AIR / (R_UNIVERSAL * temperature_K)


@dataclass
class LiftState:
    altitude_m: float
    gas_volume_m3: float
    gas_mass_kg: float
    gross_lift_kg: float        # buoyant force expressed as kg-force
    free_lift_kg: float         # gross lift minus all suspended mass
    ascent_rate_mps: float
    balloon_diameter_m: float


def moles_for_free_lift(gas: str, free_lift_kg: float, suspended_mass_kg: float,
                        balloon_mass_kg: float, z0_m: float = 0.0) -> float:
    """Moles of lift gas required at launch for a target *free lift*.

    Free lift = gross buoyant lift - (payload + balloon + gas) weight,
    all expressed as kg-force. This is the quantity a launch crew actually
    sets at the fill nozzle (a.k.a. "neck lift" once balloon+gas is removed).
    """
    st = atmosphere(z0_m)
    rho_air = air_density(st.pressure_Pa, st.temperature_K)
    M = gas_molar_mass(gas)
    rho_gas = gas_density(gas, st.pressure_Pa, st.temperature_K)
    # gross_lift = (rho_air - rho_gas)*V ; required gross lift:
    total_dead = suspended_mass_kg + balloon_mass_kg
    required_gross = free_lift_kg + total_dead
    # but gas mass itself is part of system; gross lift already nets gas buoyancy
    V = required_gross / (rho_air - rho_gas)
    n = rho_gas * V / M
    return n


def volume_from_moles(gas: str, n_moles: float, z_m: float) -> float:
    st = atmosphere(z_m)
    return n_moles * R_UNIVERSAL * st.temperature_K / st.pressure_Pa


def diameter_from_volume(V_m3: float) -> float:
    """Sphere-equivalent diameter (m) for a gas volume."""
    import math
    return 2.0 * (3.0 * V_m3 / (4.0 * math.pi)) ** (1.0 / 3.0)


def lift_state(gas: str, n_moles: float, suspended_mass_kg: float,
               balloon_mass_kg: float, z_m: float) -> LiftState:
    """Full buoyancy state of a free latex balloon at altitude z."""
    st = atmosphere(z_m)
    M = gas_molar_mass(gas)
    gas_mass = n_moles * M
    V = volume_from_moles(gas, n_moles, z_m)
    rho_air = air_density(st.pressure_Pa, st.temperature_K)
    gross_lift_N = (rho_air * V - gas_mass) * G_EARTH_STD
    gross_lift_kg = gross_lift_N / G_EARTH_STD
    total_mass = suspended_mass_kg + balloon_mass_kg
    free_lift_kg = gross_lift_kg - total_mass
    return LiftState(
        altitude_m=z_m,
        gas_volume_m3=V,
        gas_mass_kg=gas_mass,
        gross_lift_kg=gross_lift_kg,
        free_lift_kg=free_lift_kg,
        ascent_rate_mps=float("nan"),
        balloon_diameter_m=diameter_from_volume(V),
    )
