"""
U.S. Standard Atmosphere 1976 (0 - 86 km geometric).

Implements the piecewise-linear temperature profile of the 1976 model and the
hydrostatic/barometric integration for pressure and density. Reproduces the
published USSA-1976 tables to within rounding.

Reference
---------
U.S. Standard Atmosphere, 1976. NOAA-S/T 76-1562 (NOAA, NASA, USAF).
Government Printing Office, Washington, D.C., October 1976.
Section 1.3 (defining constants) and Tables in Part 4.

This module deliberately uses the *frozen* 1976 constants (R*, M0, g0, r0) from
constants.py so that the output matches the official standard tables exactly,
which is what aerospace flight-prediction tools (CUSF, SPENVIS, NPSS) expect.
"""

from __future__ import annotations

import math
from dataclasses import dataclass

from .constants import (
    USSA_R_STAR,
    USSA_M0_AIR,
    USSA_G0,
    USSA_T0,
    USSA_P0,
    USSA_EARTH_RADIUS,
    R_AIR,
)

# Base of each atmospheric layer, expressed in GEOPOTENTIAL height (m),
# with the molecular-scale temperature lapse rate L (K/m) for that layer.
# Values from USSA-1976 Table 4 (b-subscript reference levels).
#   (geopotential base [m], lapse rate [K/m])
_LAYERS = [
    (0.0,      -0.0065),   # troposphere
    (11_000.0,  0.0),      # tropopause / lower stratosphere (isothermal)
    (20_000.0,  0.0010),   # stratosphere
    (32_000.0,  0.0028),   # stratosphere
    (47_000.0,  0.0),      # stratopause (isothermal)
    (51_000.0, -0.0028),   # mesosphere
    (71_000.0, -0.0020),   # mesosphere
    (84_852.0,  None),     # top of model (~86 km geometric)
]

_GMR = USSA_G0 * USSA_M0_AIR / USSA_R_STAR  # g0*M0/R*  [K/m], barometric exponent factor


def _precompute_base_T_P():
    """Compute temperature and pressure at the base of each layer."""
    Tb = [USSA_T0]
    Pb = [USSA_P0]
    for i in range(len(_LAYERS) - 1):
        h0, L = _LAYERS[i]
        h1, _ = _LAYERS[i + 1]
        T0 = Tb[i]
        P0 = Pb[i]
        dh = h1 - h0
        if L == 0.0:
            T1 = T0
            P1 = P0 * math.exp(-_GMR * dh / T0)
        else:
            T1 = T0 + L * dh
            P1 = P0 * (T0 / T1) ** (_GMR / L)
        Tb.append(T1)
        Pb.append(P1)
    return Tb, Pb


_TB, _PB = _precompute_base_T_P()


def geometric_to_geopotential(z_m: float) -> float:
    """Convert geometric altitude z (m) to geopotential altitude h (m)."""
    r0 = USSA_EARTH_RADIUS
    return r0 * z_m / (r0 + z_m)


def geopotential_to_geometric(h_m: float) -> float:
    """Convert geopotential altitude h (m) to geometric altitude z (m)."""
    r0 = USSA_EARTH_RADIUS
    return r0 * h_m / (r0 - h_m)


@dataclass
class AtmoState:
    """Atmospheric state at a point."""
    altitude_m: float       # geometric altitude
    geopotential_m: float
    temperature_K: float
    pressure_Pa: float
    density_kgm3: float
    speed_of_sound_mps: float
    dynamic_viscosity: float  # Pa*s
    layer_index: int

    @property
    def temperature_C(self) -> float:
        return self.temperature_K - 273.15

    @property
    def pressure_hPa(self) -> float:
        return self.pressure_Pa / 100.0


def _sutherland_viscosity(T: float) -> float:
    """Dynamic viscosity of air via Sutherland's law (USSA-1976 eq. 51).

    beta = 1.458e-6 kg/(m*s*K^0.5), S = 110.4 K.
    """
    beta = 1.458e-6
    S = 110.4
    return beta * T ** 1.5 / (T + S)


def atmosphere(z_m: float, gamma: float = 1.4) -> AtmoState:
    """Return the U.S. Standard Atmosphere 1976 state at geometric altitude z.

    Parameters
    ----------
    z_m : geometric altitude in metres (valid 0 to 86 000 m).
    gamma : ratio of specific heats for the speed-of-sound calc (1.4 for air).
    """
    if z_m < -610.0:
        raise ValueError("altitude below model floor (-0.61 km)")
    h = geometric_to_geopotential(z_m)
    top_geopot = _LAYERS[-1][0]
    if h > top_geopot:
        raise ValueError(
            f"geopotential altitude {h/1000:.1f} km exceeds 1976 model top "
            f"({top_geopot/1000:.1f} km). Use a higher-altitude model above 86 km."
        )

    # locate layer
    idx = 0
    for i in range(len(_LAYERS) - 1):
        if h >= _LAYERS[i][0]:
            idx = i
    h0, L = _LAYERS[idx]
    T0 = _TB[idx]
    P0 = _PB[idx]
    dh = h - h0
    if L == 0.0:
        T = T0
        P = P0 * math.exp(-_GMR * dh / T0)
    else:
        T = T0 + L * dh
        P = P0 * (T0 / T) ** (_GMR / L)

    rho = P / (R_AIR * T)
    a = math.sqrt(gamma * R_AIR * T)
    mu = _sutherland_viscosity(T)
    return AtmoState(
        altitude_m=z_m,
        geopotential_m=h,
        temperature_K=T,
        pressure_Pa=P,
        density_kgm3=rho,
        speed_of_sound_mps=a,
        dynamic_viscosity=mu,
        layer_index=idx,
    )


def density(z_m: float) -> float:
    """Convenience: air density (kg/m^3) at geometric altitude z (m)."""
    return atmosphere(z_m).density_kgm3


def pressure(z_m: float) -> float:
    """Convenience: pressure (Pa) at geometric altitude z (m)."""
    return atmosphere(z_m).pressure_Pa


def temperature(z_m: float) -> float:
    """Convenience: temperature (K) at geometric altitude z (m)."""
    return atmosphere(z_m).temperature_K


# Reference points for self-validation (USSA-1976 published values).
# (geopotential altitude m, T [K], P [Pa]) at layer boundaries.
REFERENCE_POINTS = [
    (0.0,      288.150, 101325.0),
    (11_000.0, 216.650, 22632.06),
    (20_000.0, 216.650, 5474.889),
    (32_000.0, 228.650, 868.0187),
    (47_000.0, 270.650, 110.9063),
    (51_000.0, 270.650, 66.93887),
    (71_000.0, 214.650, 3.956420),
]
