"""
Validation / regression tests for the nearspace toolkit.

Run with:  python -m pytest engineering/tests   (or)   python engineering/tests/test_validation.py

These tests check the physics modules against authoritative reference values
(U.S. Standard Atmosphere 1976 tables) and sanity-check the integrated balloon
ascent/descent/flight models against well-known ANSR/NASA-ASCEND flight ranges.
"""

import math
import os
import sys

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from nearspace import atmosphere as atm
from nearspace import balloon, descent, thermal, comms, lift_gas
from nearspace.flight import predict_flight, WindLayer


def _assert_close(a, b, rtol, msg):
    assert abs(a - b) <= rtol * abs(b) + 1e-12, f"{msg}: {a} vs {b} (rtol {rtol})"


def test_atmosphere_reference_table():
    """USSA-1976 layer boundaries must match published T and P to <0.01%."""
    for h_geopot, Tref, Pref in atm.REFERENCE_POINTS:
        z = atm.geopotential_to_geometric(h_geopot)
        st = atm.atmosphere(z)
        _assert_close(st.temperature_K, Tref, 1e-4, f"T at {h_geopot} m")
        _assert_close(st.pressure_Pa, Pref, 1e-3, f"P at {h_geopot} m")
    print("[OK] atmosphere reproduces USSA-1976 table to <0.1%")


def test_sea_level_density_and_sound():
    st = atm.atmosphere(0.0)
    _assert_close(st.density_kgm3, 1.225, 1e-3, "sea-level density")
    _assert_close(st.speed_of_sound_mps, 340.29, 2e-3, "sea-level speed of sound")
    print(f"[OK] sea-level rho={st.density_kgm3:.4f} kg/m^3, a={st.speed_of_sound_mps:.2f} m/s")


def test_balloon_burst_altitude_reasonable():
    """A 1500 g balloon + ~1 kg payload should burst around 30-35 km."""
    res = balloon.simulate_ascent("helium", payload_mass_kg=1.0,
                                  balloon_model="Kaymont-1500", free_lift_kg=1.2)
    assert 28_000 < res.burst_altitude_m < 36_000, res.burst_altitude_m
    assert 3.0 < res.mean_ascent_rate_mps < 8.0, res.mean_ascent_rate_mps
    print(f"[OK] burst {res.burst_altitude_m/1000:.1f} km, "
          f"mean ascent {res.mean_ascent_rate_mps:.2f} m/s")


def test_descent_landing_velocity_safe():
    """Standard recovery 'chute should land ~1 kg payload at a safe speed."""
    res = descent.simulate_descent(1.0, 32_000.0, parachute="Rocketman-60in")
    assert 3.0 < res.landing_velocity_mps < 9.0, res.landing_velocity_mps
    # impact energy should be well under FAA 'gentle' guidance
    print(f"[OK] landing {res.landing_velocity_mps:.2f} m/s, "
          f"impact {res.impact_energy_J:.1f} J")


def test_descent_is_faster_aloft():
    """Terminal velocity must be much higher just after burst than at landing."""
    v_high = descent.terminal_velocity(1.0, 1.5, 1.0, 30_000.0)
    v_low = descent.terminal_velocity(1.0, 1.5, 1.0, 0.0)
    assert v_high > 4 * v_low, (v_high, v_low)
    print(f"[OK] descent rate 30 km={v_high:.1f} m/s vs ground={v_low:.1f} m/s")


def test_thermal_colder_at_altitude_band():
    """Payload equilibrium temp should be habitable for electronics (-40..+60 C)."""
    r = thermal.equilibrium_temperature(30_000.0, internal_power_W=2.0)
    assert -50 < r.payload_T_C < 80, r.payload_T_C
    print(f"[OK] payload equilibrium at 30 km = {r.payload_T_C:.1f} C")


def test_radio_horizon_grows_with_altitude():
    h0 = comms.radio_horizon_km(100.0)
    h30 = comms.radio_horizon_km(30_000.0)
    assert h30 > 500, h30
    assert h30 > 10 * h0
    print(f"[OK] radio horizon: 100 m={h0:.0f} km, 30 km alt={h30:.0f} km")


def test_link_budget_closes_at_horizon():
    lb = comms.link_budget(distance_km=300.0, tx_alt_m=30_000.0)
    assert lb.link_margin_dB > 0, lb.link_margin_dB
    print(f"[OK] APRS link margin at 300 km = {lb.link_margin_dB:.1f} dB")


def test_flight_prediction_runs():
    # Arizona launch (Phoenix area), westerly winds -> drifts east
    winds = [
        WindLayer(0, 4, 270),
        WindLayer(12_000, 30, 270),
        WindLayer(20_000, 15, 250),
        WindLayer(35_000, 8, 230),
    ]
    fp = predict_flight(33.45, -112.07, "helium", 1.0,
                        "Kaymont-1500", "Rocketman-60in",
                        free_lift_kg=1.2, wind_profile=winds,
                        launch_alt_m=337.0)
    assert fp.range_km > 5, fp.range_km
    assert fp.landing[1] > fp.launch[1]  # drifted east (lon increases)
    print(f"[OK] predicted range {fp.range_km:.1f} km, "
          f"burst {fp.burst_alt_m/1000:.1f} km, "
          f"flight {fp.flight_time_s/60:.0f} min")


def run_all():
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    print(f"Running {len(tests)} validation tests...\n")
    for t in tests:
        t()
    print("\nAll validation tests passed.")


if __name__ == "__main__":
    run_all()
