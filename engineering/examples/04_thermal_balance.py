"""
Example 4 - payload thermal balance vs altitude.

Sweeps the radiative/convective energy balance through the flight and plots the
payload equilibrium temperature against ambient air temperature, plus the
energy-flux breakdown. This is the balloon-payload analogue of the NASA T-MATS
HeatSoak / 1-D conduction blocks (see docs/07_TMATS_BRIDGE.md).
"""
import numpy as np
from _common import plt, save, ACCENT, ACCENT2, ACCENT3, ACCENT4
from nearspace import thermal
from nearspace import atmosphere as atm


def main():
    z = np.linspace(0, 35000, 120)
    Tpay, Tair = [], []
    for zi in z:
        r = thermal.equilibrium_temperature(zi, internal_power_W=2.0)
        Tpay.append(r.payload_T_C)
        Tair.append(atm.atmosphere(zi).temperature_C)
    print(f"Payload equilibrium at 30 km: {Tpay[int(120*30/35)]:.1f} C "
          f"(ambient {Tair[int(120*30/35)]:.1f} C)")

    fig, ax = plt.subplots(1, 2, figsize=(13, 6))
    zk = z / 1000.0
    ax[0].plot(Tpay, zk, color=ACCENT2, lw=2, label="Payload interior")
    ax[0].plot(Tair, zk, color=ACCENT, lw=2, ls="--", label="Ambient air")
    ax[0].axvspan(-40, 85, color="#9ccc65", alpha=0.07)
    ax[0].set_xlabel("Temperature [C]"); ax[0].set_ylabel("Altitude [km]")
    ax[0].set_title("Payload vs ambient temperature")
    ax[0].legend(facecolor="#141a30", edgecolor="#5a6a9a")

    # flux breakdown at 30 km
    r = thermal.equilibrium_temperature(30000.0, internal_power_W=2.0)
    labels = ["Solar", "Albedo", "Earth IR", "Internal", "Emit", "Conv"]
    vals = [r.Q_solar_W, r.Q_albedo_W, r.Q_earth_W, r.Q_internal_W,
            -r.Q_emit_W, -r.Q_conv_W]
    colors = [ACCENT4, ACCENT3, ACCENT2, "#ce93d8", ACCENT, "#90a4ae"]
    ax[1].bar(labels, vals, color=colors)
    ax[1].axhline(0, color="#5a6a9a", lw=1)
    ax[1].set_ylabel("Heat flow [W]  (+in / -out)")
    ax[1].set_title(f"Energy balance at 30 km (T={r.payload_T_C:.0f} C)")
    fig.suptitle("Near-space payload thermal balance  -  15 cm cube, 2 W electronics",
                 fontsize=13)
    fig.tight_layout(rect=(0, 0, 1, 0.95))
    save(fig, "04_thermal_balance.png")


if __name__ == "__main__":
    main()
