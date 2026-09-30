"""
End-to-end balloon flight-path prediction with layered winds.

Combines the ascent (balloon.py) and descent (descent.py) models with a
layered horizontal wind field to predict the ground track and landing point --
the same algorithm used by the Cambridge University Spaceflight (CUSF) /
habhub predictor and by ANSR for launch go/no-go and recovery planning.

For each integration step the payload is advected horizontally by the wind at
its current altitude. Winds are supplied as a profile of (altitude, speed,
direction_from) and interpolated. The horizontal displacement is integrated on
a sphere (great-circle "destination point" formula).

References
----------
* CUSF Landing Predictor methodology (Cambridge University Spaceflight).
* NOAA GFS / Rawinsonde wind profiles (operational wind source for predictions).
* Aviation Formulary (Ed Williams) -- destination-point on a sphere.
"""

from __future__ import annotations

import math
from dataclasses import dataclass, field

from .constants import EARTH_MEAN_RADIUS, DEG2RAD, RAD2DEG
from .balloon import simulate_ascent, AscentResult
from .descent import simulate_descent, DescentResult


@dataclass
class WindLayer:
    altitude_m: float
    speed_mps: float
    direction_from_deg: float   # meteorological: direction wind blows FROM


def interp_wind(profile: list[WindLayer], z_m: float):
    """Linear interpolation of (speed, dir) at altitude z. Returns (u, v) m/s
    in (east, north) components."""
    if not profile:
        return 0.0, 0.0
    ps = sorted(profile, key=lambda w: w.altitude_m)
    for i, layer in enumerate(ps):
        values = (layer.altitude_m, layer.speed_mps, layer.direction_from_deg)
        if not all(math.isfinite(value) for value in values):
            raise ValueError("wind layer values must be finite")
        if layer.altitude_m < 0 or layer.altitude_m > 86_000:
            raise ValueError("wind layer altitude must be between 0 and 86,000 m")
        if layer.speed_mps < 0:
            raise ValueError("wind speed cannot be negative")
        if not 0.0 <= layer.direction_from_deg < 360.0:
            raise ValueError("wind direction must be in [0, 360) degrees")
        if i and layer.altitude_m == ps[i - 1].altitude_m:
            raise ValueError("wind layer altitudes must be unique")

    def components(layer):
        # Meteorological direction is the direction the wind comes FROM.
        to_dir = (layer.direction_from_deg + 180.0) * DEG2RAD
        return layer.speed_mps * math.sin(to_dir), layer.speed_mps * math.cos(to_dir)

    if z_m <= ps[0].altitude_m:
        return components(ps[0])
    elif z_m >= ps[-1].altitude_m:
        return components(ps[-1])
    else:
        for i in range(len(ps) - 1):
            if ps[i].altitude_m <= z_m <= ps[i + 1].altitude_m:
                f = (z_m - ps[i].altitude_m) / (ps[i + 1].altitude_m - ps[i].altitude_m)
                u0, v0 = components(ps[i])
                u1, v1 = components(ps[i + 1])
                return u0 + f * (u1 - u0), v0 + f * (v1 - v0)
    raise ValueError("wind profile interpolation failed")


def destination_point(lat_deg, lon_deg, d_east_m, d_north_m):
    """Advance a coordinate by an east/north displacement on a sphere.

    Uses the direct great-circle solution so longitude remains well-behaved
    across the date line and at high latitudes.
    """
    if not all(math.isfinite(value) for value in (lat_deg, lon_deg, d_east_m, d_north_m)):
        raise ValueError("coordinates and displacement must be finite")
    if not -90.0 <= lat_deg <= 90.0:
        raise ValueError("latitude must be between -90 and 90 degrees")
    if not -180.0 <= lon_deg <= 180.0:
        raise ValueError("longitude must be between -180 and 180 degrees")

    distance_m = math.hypot(d_east_m, d_north_m)
    if distance_m == 0:
        return lat_deg, lon_deg

    R = EARTH_MEAN_RADIUS
    phi1 = lat_deg * DEG2RAD
    lambda1 = lon_deg * DEG2RAD
    angular_distance = distance_m / R
    bearing = math.atan2(d_east_m, d_north_m)
    sin_phi2 = (
        math.sin(phi1) * math.cos(angular_distance)
        + math.cos(phi1) * math.sin(angular_distance) * math.cos(bearing)
    )
    phi2 = math.asin(max(-1.0, min(1.0, sin_phi2)))
    lambda2 = lambda1 + math.atan2(
        math.sin(bearing) * math.sin(angular_distance) * math.cos(phi1),
        math.cos(angular_distance) - math.sin(phi1) * math.sin(phi2),
    )
    longitude = (lambda2 * RAD2DEG + 180.0) % 360.0 - 180.0
    return phi2 * RAD2DEG, longitude


def haversine_km(lat1, lon1, lat2, lon2):
    R = EARTH_MEAN_RADIUS / 1000.0
    p1, p2 = lat1 * DEG2RAD, lat2 * DEG2RAD
    dphi = (lat2 - lat1) * DEG2RAD
    dlmb = (lon2 - lon1) * DEG2RAD
    a = math.sin(dphi / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dlmb / 2) ** 2
    a = max(0.0, min(1.0, a))
    return 2 * R * math.atan2(math.sqrt(a), math.sqrt(1.0 - a))


@dataclass
class FlightPrediction:
    track: list = field(default_factory=list)   # list of (t, lat, lon, alt)
    launch: tuple = (0.0, 0.0)
    burst_alt_m: float = float("nan")
    landing: tuple = (0.0, 0.0)
    range_km: float = float("nan")
    flight_time_s: float = float("nan")
    ascent: AscentResult = None
    descent: DescentResult = None


def predict_flight(
    launch_lat: float,
    launch_lon: float,
    gas: str,
    payload_mass_kg: float,
    balloon_model: str,
    parachute: str,
    free_lift_kg: float,
    wind_profile: list[WindLayer],
    launch_alt_m: float = 0.0,
    ground_alt_m: float = 0.0,
    Cd_balloon: float = 0.25,
) -> FlightPrediction:
    """Predict the full ground track and landing point."""
    asc = simulate_ascent(gas, payload_mass_kg, balloon_model,
                          free_lift_kg=free_lift_kg, Cd=Cd_balloon,
                          z0_m=launch_alt_m)
    dsc = simulate_descent(payload_mass_kg, asc.burst_altitude_m,
                           parachute=parachute, ground_altitude_m=ground_alt_m)

    track = []
    lat, lon = launch_lat, launch_lon
    t = 0.0
    # ascent advection
    prev = None
    for s in asc.samples:
        if prev is not None:
            dt = s.t_s - prev.t_s
            u, v = interp_wind(wind_profile, prev.altitude_m)
            lat, lon = destination_point(lat, lon, u * dt, v * dt)
        track.append((t + s.t_s, lat, lon, s.altitude_m))
        prev = s
    t = asc.burst_time_s

    # descent advection
    prevd = None
    for s in dsc.samples:
        if prevd is not None:
            dt = s.t_s - prevd.t_s
            u, v = interp_wind(wind_profile, prevd.altitude_m)
            lat, lon = destination_point(lat, lon, u * dt, v * dt)
        track.append((t + s.t_s, lat, lon, s.altitude_m))
        prevd = s

    flight_time = t + dsc.descent_time_s
    rng = haversine_km(launch_lat, launch_lon, lat, lon)
    return FlightPrediction(
        track=track,
        launch=(launch_lat, launch_lon),
        burst_alt_m=asc.burst_altitude_m,
        landing=(lat, lon),
        range_km=rng,
        flight_time_s=flight_time,
        ascent=asc,
        descent=dsc,
    )
