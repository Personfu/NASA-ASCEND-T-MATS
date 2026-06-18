"""
Example 6 - end-to-end flight prediction with layered winds.

Predicts the full ground track and landing point for an Arizona launch
(Phoenix area, ANSR/NASA-ASCEND style) using a layered wind profile, then plots
the ground track and the altitude-vs-time mission profile.
"""
import numpy as np
from _common import plt, save, ACCENT, ACCENT2, ACCENT4
from nearspace.flight import predict_flight, WindLayer


def main():
    # Representative Arizona spring wind profile (westerlies aloft).
    winds = [
        WindLayer(337, 3, 250),
        WindLayer(5000, 12, 260),
        WindLayer(12000, 32, 270),     # jet stream core
        WindLayer(18000, 18, 265),
        WindLayer(25000, 10, 240),
        WindLayer(35000, 6, 220),
    ]
    fp = predict_flight(
        launch_lat=33.45, launch_lon=-112.07,   # Phoenix, AZ
        gas="helium", payload_mass_kg=1.0,
        balloon_model="Kaymont-1500", parachute="Rocketman-60in",
        free_lift_kg=1.2, wind_profile=winds,
        launch_alt_m=337.0, ground_alt_m=400.0,
    )
    print("Flight prediction (Phoenix, AZ launch)")
    print(f"  launch        : {fp.launch[0]:.4f}, {fp.launch[1]:.4f}")
    print(f"  burst altitude: {fp.burst_alt_m/1000:.2f} km")
    print(f"  landing       : {fp.landing[0]:.4f}, {fp.landing[1]:.4f}")
    print(f"  range         : {fp.range_km:.1f} km")
    print(f"  flight time   : {fp.flight_time_s/60:.0f} min")

    lat = np.array([p[1] for p in fp.track])
    lon = np.array([p[2] for p in fp.track])
    alt = np.array([p[3] for p in fp.track]) / 1000.0
    tmin = np.array([p[0] for p in fp.track]) / 60.0

    fig, ax = plt.subplots(1, 2, figsize=(13, 6))
    sc = ax[0].scatter(lon, lat, c=alt, cmap="plasma", s=8)
    ax[0].plot(fp.launch[1], fp.launch[0], "^", color="#9ccc65", ms=12, label="Launch")
    ax[0].plot(fp.landing[1], fp.landing[0], "v", color=ACCENT2, ms=12, label="Landing")
    ax[0].set_xlabel("Longitude [deg]"); ax[0].set_ylabel("Latitude [deg]")
    ax[0].set_title(f"Predicted ground track ({fp.range_km:.0f} km)")
    ax[0].legend(facecolor="#141a30", edgecolor="#5a6a9a")
    cb = fig.colorbar(sc, ax=ax[0]); cb.set_label("Altitude [km]")

    ax[1].plot(tmin, alt, color=ACCENT, lw=2)
    ax[1].axhline(fp.burst_alt_m / 1000.0, color=ACCENT4, ls="--", lw=1,
                  label=f"burst {fp.burst_alt_m/1000:.1f} km")
    ax[1].set_xlabel("Mission time [min]"); ax[1].set_ylabel("Altitude [km]")
    ax[1].set_title("Mission altitude profile")
    ax[1].legend(facecolor="#141a30", edgecolor="#5a6a9a")
    fig.suptitle("End-to-end flight prediction with layered winds (Phoenix, AZ)",
                 fontsize=13)
    fig.tight_layout(rect=(0, 0, 1, 0.95))
    save(fig, "06_flight_prediction.png")


if __name__ == "__main__":
    main()
