"""
Capstone - full near-space mission engineering report.

Runs every subsystem model for a single mission configuration, prints a
consolidated engineering report with pass/fail margin checks, and renders a
six-panel mission dashboard. This is the "one command" a NASA-ASCEND / ANSR
team runs to size and sanity-check a flight end to end.

Usage:  python3 run_full_mission.py
"""
import numpy as np
from _common import plt, save, ACCENT, ACCENT2, ACCENT3, ACCENT4
from nearspace import balloon, descent, thermal, comms
from nearspace import atmosphere as atm
from nearspace.flight import predict_flight, WindLayer

# ----------------------------------------------------------------------------
# Mission configuration (edit for your flight)
# ----------------------------------------------------------------------------
CFG = dict(
    name="ASCEND-S26 (Phoenix College / ANSR-style)",
    launch_lat=33.45, launch_lon=-112.07, launch_alt_m=337.0, ground_alt_m=400.0,
    gas="helium", payload_mass_kg=1.0, balloon_model="Kaymont-1500",
    parachute="Rocketman-60in", free_lift_kg=1.2,
    tx_power_W=0.5, max_track_distance_km=300.0,
    payload_side_m=0.15, internal_power_W=2.0,
)

# Engineering requirements / margins to check against
REQ = dict(
    min_burst_km=28.0, ascent_rate_band=(3.0, 8.0),
    max_landing_mps=6.0, min_link_margin_dB=10.0,
    payload_temp_band_C=(-40.0, 85.0),
)


def main():
    winds = [
        WindLayer(337, 3, 250), WindLayer(5000, 12, 260),
        WindLayer(12000, 32, 270), WindLayer(18000, 18, 265),
        WindLayer(25000, 10, 240), WindLayer(35000, 6, 220),
    ]

    asc = balloon.simulate_ascent(CFG["gas"], CFG["payload_mass_kg"],
                                  CFG["balloon_model"], free_lift_kg=CFG["free_lift_kg"],
                                  z0_m=CFG["launch_alt_m"])
    dsc = descent.simulate_descent(CFG["payload_mass_kg"], asc.burst_altitude_m,
                                   parachute=CFG["parachute"], ground_altitude_m=CFG["ground_alt_m"])
    fp = predict_flight(CFG["launch_lat"], CFG["launch_lon"], CFG["gas"],
                        CFG["payload_mass_kg"], CFG["balloon_model"], CFG["parachute"],
                        free_lift_kg=CFG["free_lift_kg"], wind_profile=winds,
                        launch_alt_m=CFG["launch_alt_m"], ground_alt_m=CFG["ground_alt_m"])
    lb = comms.link_budget(tx_power_W=CFG["tx_power_W"],
                           distance_km=CFG["max_track_distance_km"],
                           tx_alt_m=asc.burst_altitude_m)
    th = thermal.equilibrium_temperature(asc.burst_altitude_m * 0.55,
                                         side_m=CFG["payload_side_m"],
                                         internal_power_W=CFG["internal_power_W"])
    # cold-point thermal (tropopause ~ 17 km)
    th_cold = thermal.equilibrium_temperature(17000, side_m=CFG["payload_side_m"],
                                              internal_power_W=CFG["internal_power_W"])

    # ----- report -----
    def chk(ok):
        return "PASS" if ok else "FAIL"

    burst_km = asc.burst_altitude_m / 1000.0
    line = "=" * 68
    print(line)
    print(f" NEAR-SPACE MISSION ENGINEERING REPORT")
    print(f" {CFG['name']}")
    print(line)
    print(f" Balloon  : {CFG['balloon_model']}  |  Gas: {CFG['gas']}  |  "
          f"Free lift: {CFG['free_lift_kg']} kg")
    print(f" Payload  : {CFG['payload_mass_kg']} kg  |  Chute: {CFG['parachute']}")
    print(line)
    print(" ASCENT")
    print(f"   Burst altitude     : {burst_km:6.1f} km   [{chk(burst_km>=REQ['min_burst_km'])}"
          f" >= {REQ['min_burst_km']} km]")
    print(f"   Mean ascent rate   : {asc.mean_ascent_rate_mps:6.2f} m/s  "
          f"[{chk(REQ['ascent_rate_band'][0]<=asc.mean_ascent_rate_mps<=REQ['ascent_rate_band'][1])}"
          f" in {REQ['ascent_rate_band']}]")
    print(f"   Time to burst      : {asc.burst_time_s/60:6.1f} min")
    print(f"   Gas at fill        : {asc.n_moles:6.1f} mol")
    print(" DESCENT / RECOVERY")
    print(f"   Landing velocity   : {dsc.landing_velocity_mps:6.2f} m/s  "
          f"[{chk(dsc.landing_velocity_mps<=REQ['max_landing_mps'])} <= {REQ['max_landing_mps']} m/s]")
    print(f"   Impact energy      : {dsc.impact_energy_J:6.1f} J")
    print(f"   Descent time       : {dsc.descent_time_s/60:6.1f} min")
    print(" THERMAL")
    print(f"   Interior @ cold pt : {th_cold.payload_T_C:6.1f} C   "
          f"[{chk(REQ['payload_temp_band_C'][0]<=th_cold.payload_T_C<=REQ['payload_temp_band_C'][1])}"
          f" in {REQ['payload_temp_band_C']} C]")
    print(f"   Interior @ float   : {th.payload_T_C:6.1f} C")
    print(" COMMS")
    print(f"   Link margin@{CFG['max_track_distance_km']:.0f}km : {lb.link_margin_dB:6.1f} dB  "
          f"[{chk(lb.link_margin_dB>=REQ['min_link_margin_dB'])} >= {REQ['min_link_margin_dB']} dB]")
    print(f"   Radio horizon      : {lb.radio_horizon_km:6.0f} km")
    print(" TRAJECTORY")
    print(f"   Landing point      : {fp.landing[0]:.4f}, {fp.landing[1]:.4f}")
    print(f"   Downrange          : {fp.range_km:6.1f} km")
    print(f"   Total flight time  : {fp.flight_time_s/60:6.0f} min")
    print(line)

    # ----- dashboard figure -----
    fig, ax = plt.subplots(2, 3, figsize=(16, 9))

    # 1 ascent
    t = np.array(asc.times_s) / 60; alt = np.array(asc.altitudes_m) / 1000
    ax[0, 0].plot(t, alt, color=ACCENT, lw=2)
    ax[0, 0].set_title("Ascent profile"); ax[0, 0].set_xlabel("min"); ax[0, 0].set_ylabel("km")

    # 2 descent rate
    da = np.array(dsc.altitudes_m) / 1000; dv = np.array([s.velocity_mps for s in dsc.samples])
    ax[0, 1].plot(dv, da, color=ACCENT2, lw=2)
    ax[0, 1].set_title("Descent rate vs alt"); ax[0, 1].set_xlabel("m/s"); ax[0, 1].set_ylabel("km")

    # 3 ground track
    lon = np.array([p[2] for p in fp.track]); lat = np.array([p[1] for p in fp.track])
    galt = np.array([p[3] for p in fp.track]) / 1000
    sc = ax[0, 2].scatter(lon, lat, c=galt, cmap="plasma", s=6)
    ax[0, 2].plot(fp.launch[1], fp.launch[0], "^", color=ACCENT3, ms=10)
    ax[0, 2].plot(fp.landing[1], fp.landing[0], "v", color=ACCENT2, ms=10)
    ax[0, 2].set_title(f"Ground track ({fp.range_km:.0f} km)")
    ax[0, 2].set_xlabel("lon"); ax[0, 2].set_ylabel("lat")
    fig.colorbar(sc, ax=ax[0, 2], label="km")

    # 4 thermal vs altitude
    zz = np.linspace(0, asc.burst_altitude_m, 60)
    Tp = [thermal.equilibrium_temperature(z, side_m=CFG["payload_side_m"],
          internal_power_W=CFG["internal_power_W"]).payload_T_C for z in zz]
    Ta = [atm.atmosphere(z).temperature_C for z in zz]
    ax[1, 0].plot(Tp, zz/1000, color=ACCENT2, lw=2, label="payload")
    ax[1, 0].plot(Ta, zz/1000, color=ACCENT, lw=2, ls="--", label="ambient")
    ax[1, 0].set_title("Thermal"); ax[1, 0].set_xlabel("C"); ax[1, 0].set_ylabel("km")
    ax[1, 0].legend(facecolor="#141a30", edgecolor="#5a6a9a", fontsize=8)

    # 5 link margin vs distance
    dist = np.linspace(10, lb.radio_horizon_km, 100)
    mar = [comms.link_budget(tx_power_W=CFG["tx_power_W"], distance_km=d,
           tx_alt_m=asc.burst_altitude_m).link_margin_dB for d in dist]
    ax[1, 1].plot(dist, mar, color=ACCENT3, lw=2)
    ax[1, 1].axhline(REQ["min_link_margin_dB"], color=ACCENT4, ls=":", lw=1)
    ax[1, 1].set_title("APRS link margin"); ax[1, 1].set_xlabel("km"); ax[1, 1].set_ylabel("dB")

    # 6 requirement scorecard
    ax[1, 2].axis("off")
    checks = [
        ("Burst >= 28 km", burst_km >= REQ["min_burst_km"]),
        ("Ascent 3-8 m/s", REQ["ascent_rate_band"][0] <= asc.mean_ascent_rate_mps <= REQ["ascent_rate_band"][1]),
        ("Landing <= 6 m/s", dsc.landing_velocity_mps <= REQ["max_landing_mps"]),
        ("Thermal in band", REQ["payload_temp_band_C"][0] <= th_cold.payload_T_C <= REQ["payload_temp_band_C"][1]),
        ("Link margin >= 10 dB", lb.link_margin_dB >= REQ["min_link_margin_dB"]),
    ]
    ax[1, 2].set_title("Requirement scorecard", color="#dce3ff")
    for i, (name, ok) in enumerate(checks):
        col = ACCENT3 if ok else ACCENT2
        ax[1, 2].text(0.05, 0.85 - i * 0.16, f"{'PASS' if ok else 'FAIL'}  {name}",
                      color=col, fontsize=13, family="monospace",
                      transform=ax[1, 2].transAxes)

    fig.suptitle(f"Near-Space Mission Dashboard  -  {CFG['name']}", fontsize=15)
    fig.tight_layout(rect=(0, 0, 1, 0.96))
    save(fig, "00_mission_dashboard.png")


if __name__ == "__main__":
    main()
