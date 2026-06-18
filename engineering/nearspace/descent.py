"""
Parachute descent and landing-velocity model.

After burst, the payload train falls under a parachute. Terminal velocity is
set by the balance of weight and drag:

    m g = 1/2 * rho_air(z) * Cd * S * v^2
    => v(z) = sqrt( 2 m g / (rho_air(z) * Cd * S) )

Because air density falls steeply with altitude, descent rate is very high just
after burst (often >40 m/s near 30 km) and slows to a safe landing speed near
the surface. The model integrates the descent in altitude steps using the
local USSA-1976 density, which captures this strong altitude dependence -- the
quantity recovery crews and the FAA care about (impact kinetic energy).

References
----------
* Knacke, T.W. (1992), "Parachute Recovery Systems Design Manual,"
  NWC TP 6575, Naval Weapons Center (public).
* FAA AC 101-1 / 14 CFR Part 101 (unmanned free-balloon impact-energy limits).
* CUSF / habhub landing-predictor descent-rate methodology.
"""

from __future__ import annotations

import math
from dataclasses import dataclass, field

from .constants import G_EARTH_STD
from .atmosphere import atmosphere

# Typical hobby / ASCEND recovery parachutes: nominal drag area S*Cd reference.
# Drag coefficient of a round canopy ~0.8-1.5 depending on type; we expose both.
PARACHUTE_CATALOG = {
    # name -> dict(diameter_m, Cd)
    "Rocketman-36in":  {"diameter_m": 0.914, "Cd": 0.97},
    "Rocketman-48in":  {"diameter_m": 1.219, "Cd": 0.97},
    "Rocketman-60in":  {"diameter_m": 1.524, "Cd": 0.97},
    "Rocketman-84in":  {"diameter_m": 2.134, "Cd": 0.97},
    "SkyAngle-Cert3":  {"diameter_m": 1.500, "Cd": 1.40},
    "Spherachute-60in": {"diameter_m": 1.524, "Cd": 0.75},
}


@dataclass
class DescentSample:
    t_s: float
    altitude_m: float
    velocity_mps: float
    rho_kgm3: float


@dataclass
class DescentResult:
    samples: list = field(default_factory=list)
    landing_velocity_mps: float = float("nan")
    descent_time_s: float = float("nan")
    impact_energy_J: float = float("nan")
    parachute_area_m2: float = float("nan")
    Cd: float = float("nan")

    @property
    def altitudes_m(self):
        return [s.altitude_m for s in self.samples]

    @property
    def times_s(self):
        return [s.t_s for s in self.samples]


def terminal_velocity(mass_kg: float, S_m2: float, Cd: float, z_m: float) -> float:
    """Steady terminal velocity (m/s) at geometric altitude z."""
    rho = atmosphere(z_m).density_kgm3
    return math.sqrt(2.0 * mass_kg * G_EARTH_STD / (rho * Cd * S_m2))


def parachute_area(diameter_m: float) -> float:
    return math.pi / 4.0 * diameter_m ** 2


def simulate_descent(
    mass_kg: float,
    burst_altitude_m: float,
    parachute: str | None = "Rocketman-60in",
    diameter_m: float | None = None,
    Cd: float | None = None,
    dz_m: float = 20.0,
    ground_altitude_m: float = 0.0,
) -> DescentResult:
    """Quasi-steady terminal-velocity descent from burst to ground.

    Uses the local terminal velocity at each altitude step (the payload is
    near terminal velocity for essentially the whole descent except the first
    few seconds after burst).
    """
    if parachute in (PARACHUTE_CATALOG or {}) and diameter_m is None:
        spec = PARACHUTE_CATALOG[parachute]
        D = spec["diameter_m"]
        cd = spec["Cd"] if Cd is None else Cd
    else:
        if diameter_m is None:
            raise ValueError("supply parachute name or diameter_m")
        D = diameter_m
        cd = 1.0 if Cd is None else Cd

    S = parachute_area(D)
    res = DescentResult(parachute_area_m2=S, Cd=cd)

    z = burst_altitude_m
    t = 0.0
    while z > ground_altitude_m:
        v = terminal_velocity(mass_kg, S, cd, z)
        rho = atmosphere(z).density_kgm3
        res.samples.append(DescentSample(t_s=t, altitude_m=z, velocity_mps=v, rho_kgm3=rho))
        dt = dz_m / v
        z -= dz_m
        t += dt

    v_land = terminal_velocity(mass_kg, S, cd, max(ground_altitude_m, 0.0))
    res.samples.append(DescentSample(t_s=t, altitude_m=ground_altitude_m,
                                     velocity_mps=v_land,
                                     rho_kgm3=atmosphere(ground_altitude_m).density_kgm3))
    res.landing_velocity_mps = v_land
    res.descent_time_s = t
    res.impact_energy_J = 0.5 * mass_kg * v_land ** 2
    return res
