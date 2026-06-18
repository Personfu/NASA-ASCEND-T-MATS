"""
APRS / VHF link budget and radio horizon for balloon telemetry & recovery.

Arizona Near Space Research (ANSR) and most NASA ASCEND teams track payloads
with APRS on the 2 m amateur band. This module computes:

  * radio horizon (line-of-sight range) vs altitude, with the 4/3-Earth
    refraction model used in VHF propagation,
  * free-space path loss (Friis), and
  * a received-signal / link-margin budget against a receiver sensitivity.

At 30 km a payload can be heard ~600 km away by line of sight, which is why
APRS digipeaters and the APRS-IS / aprs.fi network recover the whole track.

References
----------
* APRS Protocol Reference v1.0.1 (Bob Bruninga WB4APR / TAPR).
* ARRL Antenna Book / VHF-UHF propagation (4/3 Earth radio horizon).
* ITU-R P.525 (free-space attenuation), P.834 (refraction).
* ANSR operating practice: 144.39 MHz (US APRS), historically 144.34 MHz in AZ.
* FCC Part 97 amateur service / payload telemetry conventions.
"""

from __future__ import annotations

import math
from dataclasses import dataclass

from .constants import C_LIGHT, EARTH_MEAN_RADIUS

# Common 2 m APRS frequencies
APRS_FREQ_US = 144.390e6     # MHz, North America primary APRS
APRS_FREQ_AZ = 144.340e6     # MHz, regional (ANSR has used this for balloons)
APRS_FREQ_EU = 144.800e6     # MHz, Europe/IARU R1


@dataclass
class LinkBudget:
    frequency_Hz: float
    distance_km: float
    fspl_dB: float
    eirp_dBm: float
    rx_power_dBm: float
    rx_sensitivity_dBm: float
    link_margin_dB: float
    radio_horizon_km: float


def radio_horizon_km(tx_alt_m: float, rx_alt_m: float = 10.0,
                     k_factor: float = 4.0 / 3.0) -> float:
    """Line-of-sight radio horizon between a balloon and a ground station.

    Uses the effective-Earth-radius (k-factor) model: the geometric horizon
    distance from height h over an Earth of effective radius k*R is
    d = sqrt(2*k*R*h). Total range is the sum of both stations' horizons.
    """
    Re = EARTH_MEAN_RADIUS * k_factor
    d_tx = math.sqrt(2.0 * Re * max(tx_alt_m, 0.0))
    d_rx = math.sqrt(2.0 * Re * max(rx_alt_m, 0.0))
    return (d_tx + d_rx) / 1000.0


def free_space_path_loss_dB(distance_m: float, frequency_Hz: float) -> float:
    """Friis free-space path loss in dB (ITU-R P.525)."""
    if distance_m <= 0:
        return 0.0
    return 20.0 * math.log10(4.0 * math.pi * distance_m * frequency_Hz / C_LIGHT)


def link_budget(
    tx_power_W: float = 0.5,
    tx_gain_dBi: float = 0.0,
    rx_gain_dBi: float = 3.0,
    cable_loss_dB: float = 1.0,
    distance_km: float = 200.0,
    frequency_Hz: float = APRS_FREQ_US,
    rx_sensitivity_dBm: float = -118.0,
    tx_alt_m: float = 30_000.0,
    rx_alt_m: float = 10.0,
) -> LinkBudget:
    """Compute a 2 m APRS downlink budget.

    Defaults model a typical 0.5 W HX1 / RTTY tracker with a 1/4-wave whip
    (~0 dBi) heard by a ground station with a modest 3 dBi vertical.
    rx_sensitivity for 1200-baud AFSK APRS is around -118 dBm.
    """
    tx_power_dBm = 10.0 * math.log10(tx_power_W * 1000.0)
    eirp_dBm = tx_power_dBm + tx_gain_dBi - cable_loss_dB
    fspl = free_space_path_loss_dB(distance_km * 1000.0, frequency_Hz)
    rx_power_dBm = eirp_dBm - fspl + rx_gain_dBi
    margin = rx_power_dBm - rx_sensitivity_dBm
    horizon = radio_horizon_km(tx_alt_m, rx_alt_m)
    return LinkBudget(
        frequency_Hz=frequency_Hz,
        distance_km=distance_km,
        fspl_dB=fspl,
        eirp_dBm=eirp_dBm,
        rx_power_dBm=rx_power_dBm,
        rx_sensitivity_dBm=rx_sensitivity_dBm,
        link_margin_dB=margin,
        radio_horizon_km=horizon,
    )
