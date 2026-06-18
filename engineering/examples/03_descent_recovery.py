"""
Example 3 - parachute descent & recovery.

Shows the strong altitude dependence of descent rate (fast just after burst,
slow at landing) and compares parachute sizes for landing velocity and impact
energy -- the safety quantity bounded by 14 CFR Part 101.
"""
import numpy as np
from _common import plt, save, ACCENT, ACCENT2, ACCENT3, ACCENT4
from nearspace import descent


def main():
    res = descent.simulate_descent(1.2, 33_000.0, parachute="Rocketman-60in")
    print("Descent: 1.2 kg payload, Rocketman-60in chute, burst 33 km")
    print(f"  landing velocity : {res.landing_velocity_mps:.2f} m/s")
    print(f"  descent time     : {res.descent_time_s/60:.1f} min")
    print(f"  impact energy    : {res.impact_energy_J:.1f} J")

    alt = np.array(res.altitudes_m) / 1000.0
    v = np.array([s.velocity_mps for s in res.samples])
    t = np.array(res.times_s) / 60.0

    fig, ax = plt.subplots(1, 2, figsize=(12, 5.5))
    ax[0].plot(v, alt, color=ACCENT, lw=2)
    ax[0].set_xlabel("Descent rate [m/s]"); ax[0].set_ylabel("Altitude [km]")
    ax[0].set_title("Terminal velocity vs altitude")
    ax[1].plot(t, alt, color=ACCENT2, lw=2)
    ax[1].set_xlabel("Time after burst [min]"); ax[1].set_ylabel("Altitude [km]")
    ax[1].set_title(f"Descent profile ({res.descent_time_s/60:.0f} min)")
    fig.suptitle("Parachute descent  -  1.2 kg payload, 60 in chute", fontsize=13)
    fig.tight_layout(rect=(0, 0, 1, 0.95))
    save(fig, "03_descent_profile.png")

    # Parachute comparison for landing velocity & impact energy
    names = list(descent.PARACHUTE_CATALOG.keys())
    vland, energy = [], []
    for n in names:
        r = descent.simulate_descent(1.2, 33_000.0, parachute=n)
        vland.append(r.landing_velocity_mps)
        energy.append(r.impact_energy_J)
    x = np.arange(len(names))
    fig2, ax2 = plt.subplots(1, 2, figsize=(13, 5.5))
    ax2[0].bar(x, vland, color=ACCENT3)
    ax2[0].set_xticks(x); ax2[0].set_xticklabels(names, rotation=35, ha="right")
    ax2[0].set_ylabel("Landing velocity [m/s]"); ax2[0].set_title("Landing velocity by chute")
    ax2[1].bar(x, energy, color=ACCENT4)
    ax2[1].set_xticks(x); ax2[1].set_xticklabels(names, rotation=35, ha="right")
    ax2[1].set_ylabel("Impact energy [J]"); ax2[1].set_title("Impact energy by chute")
    fig2.suptitle("Recovery trade study (1.2 kg payload)", fontsize=13)
    fig2.tight_layout(rect=(0, 0, 1, 0.95))
    save(fig2, "03b_parachute_trade.png")


if __name__ == "__main__":
    main()
