"""
Payload radiative/convective thermal balance in near-space.

A near-space payload sits in a hostile thermal environment: near vacuum (low
convective coupling), intense unattenuated sunlight, cold sky, and a warm Earth
below. The steady-state internal temperature is found by balancing energy in
and out:

    Q_in  = Q_solar + Q_albedo + Q_earth_IR + Q_internal
    Q_out = Q_emit  + Q_convection
    at steady state Q_in = Q_out  ->  solve for T_payload

with
    Q_solar      = alpha * G_sun  * A_sun          (direct beam, projected area)
    Q_albedo     = alpha * a * G_sun * A_up * F     (reflected sunlight)
    Q_earth_IR   = eps   * Q_lw  * A_down * F        (Earth longwave)
    Q_emit       = eps * sigma * A_total * T^4       (gray-body emission)
    Q_convection = h(z) * A_total * (T - T_air)      (free convection, weak aloft)

This is the same first-law energy-balance / heat-soak approach used by the
NASA T-MATS HeatSoak and 1-D conduction blocks (see docs/07_TMATS_BRIDGE.md) --
applied to a balloon payload instead of a turbine casing.

References
----------
* Gilmore, D.G. (ed.), "Spacecraft Thermal Control Handbook," Vol. 1,
  The Aerospace Press / AIAA, 2002 (radiative balance, alpha/eps).
* NASA SP-8055, "Prediction of Temperature Variation in Spacecraft."
* USSA-1976 for ambient T(z), rho(z).
* Incropera & DeWitt, "Fundamentals of Heat and Mass Transfer" (free convection).
"""

from __future__ import annotations

import math
from dataclasses import dataclass

from .constants import (
    STEFAN_BOLTZMANN,
    SOLAR_CONSTANT,
    ALBEDO_EARTH,
    EARTH_IR_FLUX,
)
from .atmosphere import atmosphere


@dataclass
class ThermalResult:
    altitude_m: float
    payload_T_K: float
    payload_T_C: float
    Q_solar_W: float
    Q_albedo_W: float
    Q_earth_W: float
    Q_internal_W: float
    Q_emit_W: float
    Q_conv_W: float


def _free_convection_h(T_s: float, T_air: float, L_char: float, z_m: float) -> float:
    """Approximate free-convection coefficient (W/m^2/K) for a small box.

    Uses a Nusselt correlation for a vertical plate / small enclosure,
    Nu = 0.59 Ra^(1/4) (laminar), with air properties scaled by ambient
    density. At high altitude density -> 0 so h -> 0 (near-radiative regime),
    which is the dominant physical effect we want to capture.
    """
    st = atmosphere(z_m)
    rho = st.density_kgm3
    if rho <= 0 or abs(T_s - T_air) < 1e-6:
        return 0.0
    # air thermophysical properties (approx, evaluated near 250 K)
    k_air = 0.022          # W/m/K
    nu0 = 1.5e-5           # m^2/s kinematic viscosity at sea level ~
    nu = nu0 * (1.225 / rho)  # kinematic viscosity scales ~1/rho
    alpha_th = nu / 0.71   # thermal diffusivity, Pr~0.71
    beta = 1.0 / T_air     # ideal-gas expansion coefficient
    g = 9.80665
    Ra = g * beta * abs(T_s - T_air) * L_char ** 3 / (nu * alpha_th)
    if Ra <= 0:
        return 0.0
    Nu = 0.59 * Ra ** 0.25
    Nu = max(Nu, 1.0)
    return Nu * k_air / L_char


def equilibrium_temperature(
    altitude_m: float,
    side_m: float = 0.15,
    absorptivity: float = 0.6,
    emissivity: float = 0.85,
    internal_power_W: float = 2.0,
    sun_elevation_deg: float = 45.0,
    view_factor_earth: float = 0.5,
    include_convection: bool = True,
) -> ThermalResult:
    """Steady-state internal temperature of a cubic payload at altitude z.

    Parameters
    ----------
    side_m          : payload cube edge length (m)
    absorptivity    : solar absorptivity alpha (surface finish)
    emissivity      : IR emissivity eps (surface finish)
    internal_power_W: electronics dissipation inside the box
    sun_elevation_deg : solar elevation above horizon
    view_factor_earth : geometric view factor to Earth (~0.5 at altitude)
    """
    A_face = side_m ** 2
    A_total = 6.0 * A_face
    # projected area to the sun for a cube ~ one face plus geometry; use ~1.2 faces
    A_sun = 1.2 * A_face * max(math.sin(math.radians(sun_elevation_deg)), 0.0)
    A_up = A_face        # downward-facing area sees albedo
    A_down = A_face      # upward-facing area sees Earth IR (approx)

    st = atmosphere(altitude_m)
    T_air = st.temperature_K

    G = SOLAR_CONSTANT
    Q_solar = absorptivity * G * A_sun
    Q_albedo = absorptivity * ALBEDO_EARTH * G * A_up * view_factor_earth
    Q_earth = emissivity * EARTH_IR_FLUX * A_down * view_factor_earth
    Q_internal = internal_power_W

    Q_in_fixed = Q_solar + Q_albedo + Q_earth + Q_internal

    # Solve  Q_in_fixed = eps*sigma*A_total*T^4 + h*A_total*(T - T_air)
    # by bisection on T.
    def residual(T):
        Q_emit = emissivity * STEFAN_BOLTZMANN * A_total * T ** 4
        if include_convection:
            h = _free_convection_h(T, T_air, side_m, altitude_m)
        else:
            h = 0.0
        Q_conv = h * A_total * (T - T_air)
        return Q_in_fixed - Q_emit - Q_conv

    lo, hi = 100.0, 500.0
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        if residual(mid) > 0:
            lo = mid
        else:
            hi = mid
    T = 0.5 * (lo + hi)

    Q_emit = emissivity * STEFAN_BOLTZMANN * A_total * T ** 4
    h = _free_convection_h(T, T_air, side_m, altitude_m) if include_convection else 0.0
    Q_conv = h * A_total * (T - T_air)

    return ThermalResult(
        altitude_m=altitude_m,
        payload_T_K=T,
        payload_T_C=T - 273.15,
        Q_solar_W=Q_solar,
        Q_albedo_W=Q_albedo,
        Q_earth_W=Q_earth,
        Q_internal_W=Q_internal,
        Q_emit_W=Q_emit,
        Q_conv_W=Q_conv,
    )
