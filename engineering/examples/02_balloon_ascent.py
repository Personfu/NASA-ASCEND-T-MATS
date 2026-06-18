"""
Example 2 - balloon ascent & burst prediction.

Simulates a helium-filled latex sounding-balloon ascent for an ASCEND-class
payload and plots altitude, ascent rate, envelope diameter, and gas volume vs
time. Also sweeps free lift to show its effect on burst altitude and ascent
rate -- the core launch-day trade ANSR crews tune at the fill nozzle.
"""
import numpy as np
from _common import plt, save, ACCENT, ACCENT2, ACCENT3, ACCENT4
from nearspace import balloon


def main():
    res = balloon.simulate_ascent("helium", payload_mass_kg=1.0,
                                  balloon_model="Kaymont-1500", free_lift_kg=1.2)
    print(f"Balloon: Kaymont-1500  gas: helium  payload: 1.0 kg  free lift: 1.2 kg")
    print(f"  burst altitude   : {res.burst_altitude_m/1000:.2f} km")
    print(f"  burst diameter   : {res.burst_diameter_m:.2f} m")
    print(f"  time to burst    : {res.burst_time_s/60:.1f} min")
    print(f"  mean ascent rate : {res.mean_ascent_rate_mps:.2f} m/s")
    print(f"  gas at fill      : {res.n_moles:.1f} mol")

    t = np.array(res.times_s) / 60.0
    alt = np.array(res.altitudes_m) / 1000.0
    w = np.array([s.ascent_rate_mps for s in res.samples])
    D = np.array([s.diameter_m for s in res.samples])
    V = np.array([s.gas_volume_m3 for s in res.samples])

    fig, ax = plt.subplots(2, 2, figsize=(12, 9))
    ax[0, 0].plot(t, alt, color=ACCENT, lw=2)
    ax[0, 0].set_xlabel("Time [min]"); ax[0, 0].set_ylabel("Altitude [km]")
    ax[0, 0].set_title(f"Ascent profile (burst {res.burst_altitude_m/1000:.1f} km)")

    ax[0, 1].plot(w, alt, color=ACCENT2, lw=2)
    ax[0, 1].set_xlabel("Ascent rate [m/s]"); ax[0, 1].set_ylabel("Altitude [km]")
    ax[0, 1].set_title("Ascent rate vs altitude")

    ax[1, 0].plot(alt, D, color=ACCENT3, lw=2)
    ax[1, 0].axhline(res.burst_diameter_m, color=ACCENT4, ls="--", lw=1)
    ax[1, 0].set_xlabel("Altitude [km]"); ax[1, 0].set_ylabel("Envelope diameter [m]")
    ax[1, 0].set_title("Envelope expansion to burst")

    ax[1, 1].plot(alt, V, color=ACCENT4, lw=2)
    ax[1, 1].set_xlabel("Altitude [km]"); ax[1, 1].set_ylabel("Gas volume [m$^3$]")
    ax[1, 1].set_title("Lift-gas volume (ideal gas, ambient P,T)")

    fig.suptitle("Latex sounding-balloon ascent  -  Kaymont-1500, He, 1 kg payload",
                 fontsize=13)
    fig.tight_layout(rect=(0, 0, 1, 0.97))
    save(fig, "02_balloon_ascent.png")

    # Free-lift sweep
    fls = np.linspace(0.6, 2.5, 12)
    bursts, rates = [], []
    for fl in fls:
        r = balloon.simulate_ascent("helium", 1.0, "Kaymont-1500", free_lift_kg=fl)
        bursts.append(r.burst_altitude_m / 1000.0)
        rates.append(r.mean_ascent_rate_mps)
    fig2, ax2 = plt.subplots(1, 2, figsize=(12, 5))
    ax2[0].plot(fls, bursts, "o-", color=ACCENT)
    ax2[0].set_xlabel("Free lift [kg]"); ax2[0].set_ylabel("Burst altitude [km]")
    ax2[0].set_title("Free lift vs burst altitude")
    ax2[1].plot(fls, rates, "o-", color=ACCENT2)
    ax2[1].set_xlabel("Free lift [kg]"); ax2[1].set_ylabel("Mean ascent rate [m/s]")
    ax2[1].set_title("Free lift vs ascent rate")
    fig2.suptitle("Launch-day trade study: free-lift tuning (Kaymont-1500, He)",
                  fontsize=13)
    fig2.tight_layout(rect=(0, 0, 1, 0.95))
    save(fig2, "02b_free_lift_trade.png")


if __name__ == "__main__":
    main()
