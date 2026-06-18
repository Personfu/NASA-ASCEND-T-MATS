"""
Example 1 - U.S. Standard Atmosphere 1976 profile (0-86 km).

Prints a validation table against the official USSA-1976 layer boundaries and
plots temperature, pressure, and density vs altitude through the near-space
flight regime.
"""
import numpy as np
from _common import plt, save, ACCENT, ACCENT2, ACCENT3
from nearspace import atmosphere as atm


def main():
    print("U.S. Standard Atmosphere 1976 - validation vs published table")
    print(f"{'h[km]':>6} {'T[K]':>9} {'P[Pa]':>12} {'rho[kg/m3]':>12}")
    for h, Tref, Pref in atm.REFERENCE_POINTS:
        z = atm.geopotential_to_geometric(h)
        s = atm.atmosphere(z)
        print(f"{h/1000:6.0f} {s.temperature_K:9.3f} {s.pressure_Pa:12.4f} {s.density_kgm3:12.6f}")

    z = np.linspace(0, 84000, 600)
    T = np.array([atm.atmosphere(zi).temperature_K for zi in z])
    P = np.array([atm.atmosphere(zi).pressure_Pa for zi in z])
    rho = np.array([atm.atmosphere(zi).density_kgm3 for zi in z])

    fig, ax = plt.subplots(1, 3, figsize=(13, 6))
    zk = z / 1000.0

    ax[0].plot(T, zk, color=ACCENT, lw=2)
    ax[0].set_xlabel("Temperature [K]"); ax[0].set_ylabel("Geometric altitude [km]")
    ax[0].set_title("Temperature profile")

    ax[1].semilogx(P, zk, color=ACCENT2, lw=2)
    ax[1].set_xlabel("Pressure [Pa]"); ax[1].set_title("Pressure (log)")

    ax[2].semilogx(rho, zk, color=ACCENT3, lw=2)
    ax[2].set_xlabel("Density [kg/m$^3$]"); ax[2].set_title("Density (log)")

    # mark the near-space flight band
    for a in ax:
        a.axhspan(18, 38, color="#4fc3f7", alpha=0.07)
        a.axhline(30, color="#ffca28", ls="--", lw=0.8, alpha=0.6)
    fig.suptitle("U.S. Standard Atmosphere 1976  -  near-space ballooning regime "
                 "(typical burst 30-35 km shaded)", fontsize=12)
    fig.tight_layout(rect=(0, 0, 1, 0.96))
    save(fig, "01_atmosphere_profile.png")


if __name__ == "__main__":
    main()
