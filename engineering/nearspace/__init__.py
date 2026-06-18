"""
nearspace - a high-altitude / near-space ballooning engineering toolkit.

Inspired by Arizona Near Space Research (ANSR) practice and built for the
NASA ASCEND high-altitude balloon payload program. Every model is grounded in
public/government sources (NASA, NOAA, NIST, FAA, USAF) -- see docs/REFERENCES.md.

Modules
-------
constants    : NIST/USSA/WGS-84 physical constants
atmosphere   : U.S. Standard Atmosphere 1976 (0-86 km)
lift_gas     : helium/hydrogen buoyancy and gas thermodynamics
balloon      : latex sounding-balloon ascent and burst prediction
descent      : parachute descent and landing-velocity model
thermal      : payload radiative/convective thermal balance in near-space
comms        : APRS / VHF link budget and radio horizon
flight       : end-to-end trajectory prediction with layered winds

The package depends only on numpy (and matplotlib for the example plots).
"""

from . import constants  # noqa: F401

__all__ = [
    "constants",
    "atmosphere",
    "lift_gas",
    "balloon",
    "descent",
    "thermal",
    "comms",
    "flight",
]

__version__ = "1.0.0"
