"""
Example 5 - APRS / 2 m VHF link budget and radio horizon.

Computes the line-of-sight radio horizon vs altitude and the received-power /
link-margin budget vs ground distance for a typical 0.5 W APRS balloon tracker
on 144.39 MHz -- the telemetry & recovery backbone used by ANSR / NASA ASCEND.
"""
import numpy as np
from _common import plt, save, ACCENT, ACCENT2, ACCENT4
from nearspace import comms


def main():
    print("APRS link budget (0.5 W, 144.39 MHz)")
    for d in (100, 300, 600):
        lb = comms.link_budget(distance_km=d, tx_alt_m=30000)
        print(f"  {d:4d} km: FSPL {lb.fspl_dB:5.1f} dB, "
              f"Rx {lb.rx_power_dBm:6.1f} dBm, margin {lb.link_margin_dB:5.1f} dB")
    print(f"  radio horizon at 30 km: {comms.radio_horizon_km(30000):.0f} km")

    alt = np.linspace(0, 35000, 200)
    horizon = np.array([comms.radio_horizon_km(a) for a in alt])

    dist = np.linspace(10, 800, 200)
    margin = np.array([comms.link_budget(distance_km=d, tx_alt_m=30000).link_margin_dB
                       for d in dist])

    fig, ax = plt.subplots(1, 2, figsize=(13, 5.5))
    ax[0].plot(horizon, alt / 1000.0, color=ACCENT, lw=2)
    ax[0].set_xlabel("Radio horizon [km]"); ax[0].set_ylabel("Altitude [km]")
    ax[0].set_title("Line-of-sight horizon (4/3 Earth)")

    ax[1].plot(dist, margin, color=ACCENT2, lw=2)
    ax[1].axhline(0, color=ACCENT4, ls="--", lw=1, label="0 dB (closure limit)")
    ax[1].axhline(10, color="#9ccc65", ls=":", lw=1, label="10 dB design margin")
    ax[1].set_xlabel("Ground distance [km]"); ax[1].set_ylabel("Link margin [dB]")
    ax[1].set_title("APRS downlink margin (0.5 W, 30 km alt)")
    ax[1].legend(facecolor="#141a30", edgecolor="#5a6a9a")
    fig.suptitle("Telemetry & recovery link analysis  -  2 m APRS", fontsize=13)
    fig.tight_layout(rect=(0, 0, 1, 0.95))
    save(fig, "05_aprs_link_budget.png")


if __name__ == "__main__":
    main()
