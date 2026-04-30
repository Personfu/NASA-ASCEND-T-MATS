# Phoenix College NASA ASCEND - Spring 2026 MATLAB Simulation Suite

> **Mission:** Balloon-2 / KA7NSR-15 - Launched 2026-03-28 16:38:54 UTC
> **Authoring lead:** *Personfu*, Senior Engineering / Simulation Architect
> **Target audience:** Phoenix College NASA ASCEND team - Graduate-master engineering review

This repository is a complete, data-driven MATLAB reconstruction of the
Spring 2026 ASCEND high-altitude balloon flight. Every model is anchored
to the *actual* raw flight data captured during the mission and provides
bit-for-bit traceability from raw spreadsheet rows -> ingested
timetables -> physics models -> validation -> figures -> mission report.

---

## 1. Repository layout

```
matlab_ASCEND_S26/
+- ASCEND_S26_run.m          % master driver (run this)
+- config/
|  +- ASCEND_S26_config.m    % constants, paths, mission metadata
|  +- payload_systems.m      % full subsystem BOM, masses, MOI, FAA notes
+- src/
|  +- io/
|  |  +- ingest_*.m          % per-dataset CSV -> timetable parsers
|  |  +- ingest_all.m        % batch ingestion + cache
|  |  +- write_mission_report.m
|  +- models/
|  |  +- atm_us1976.m        % US Standard Atmosphere 1976
|  |  +- wgs84_inverse.m     % Vincenty inverse geodesic
|  |  +- wgs84_destination.m % Vincenty direct geodesic
|  |  +- compute_ground_track.m
|  |  +- build_wind_profile.m
|  |  +- simulate_ascent.m    % 1-D ideal-gas balloon RK4
|  |  +- simulate_descent.m   % 1-D parachute RK4
|  |  +- simulate_3d_ascent.m % 3-DOF wind-coupled RK4
|  |  +- simulate_3d_descent.m% opening-shock model (Pflanz)
|  |  +- simulate_thermal.m   % lumped-capacitance, 6 sources
|  |  +- simulate_power.m     % L91 pack coulomb counting
|  |  +- model_cosmic_ray.m   % Pfotzer-Regener
|  |  +- model_uv_ozone.m     % Beer-Lambert UV / O3 column
|  |  +- igrf13_field.m       % IGRF-13 dipole approximation
|  |  +- sensor_fusion_attitude.m % Madgwick 9-DOF
|  |  +- monte_carlo_dispersion.m % CEP50/95 ellipse
|  |  +- link_budget_aprs.m   % 144.39 MHz link budget
|  |  +- detect_flight_events.m % release/strato/Armstrong/Pfotzer/apex
|  |  +- analyze_flight_dynamics.m % q,Mach,Re,energy,N^2,shear
|  |  +- validation_suite.m   % residuals / RMSE / R^2
|  +- viz/
|     +- viz_trajectory.m
|     +- viz_atmosphere.m
|     +- viz_science.m
|     +- viz_imu.m
|     +- viz_3d_globe.m
|     +- viz_simulation.m
|     +- viz_thermal_power.m
|     +- viz_wind_profile.m
|     +- viz_link_budget.m
|     +- viz_dispersion.m
|     +- viz_payload.m
|     +- viz_phase_timeline.m
|     +- viz_aerodynamics.m
|     +- animate_flight.m
+- src/io/
|  +- export_kml.m            % Google Earth KML
|  +- export_gpx.m            % GPX 1.1 chase track
|  +- write_html_dashboard.m  % single-file mission HTML
+- data/
|  +- raw/                   % CSVs converted from XLSX via tools/xlsx_to_csv.py
|  +- processed/             % cached .mat files
+- reports/
|  +- ASCEND_S26_summary.txt
|  +- ASCEND_S26_MISSION_REPORT.md
+- figures/
+- docs/
|  +- THEORY.md
|  +- OPERATIONS.md
|  +- DATA_DICTIONARY.md
+- tools/
   +- xlsx_to_csv.py
```

## 2. Quick start

```matlab
>> cd matlab_ASCEND_S26
>> results = ASCEND_S26_run();          % full pipeline
>> animate_flight(results.D, results.cfg);  % render mp4
```

Optional flags:
- `ASCEND_S26_run('NoSim',true)` - skip dynamic simulation (fast preview)
- `ASCEND_S26_run('Quick',true)`  - skip thermal/power/Monte-Carlo

## 3. Mission constants (excerpt)

| Item                     | Value                              |
|--------------------------|------------------------------------|
| Launch UTC               | 2026-03-28 16:38:54                |
| Launch site              | 32.87533 N, 112.0495 W, 419 m MSL |
| Burst altitude           | 25,145 m (82,497 ft)               |
| Peak descent rate        | 28.4 m/s (63.6 mph)                |
| Impact speed             | 6.7  m/s (15.1 mph)                |
| Balloon                  | Kaymont 1500 g latex, He-filled    |
| Parachute                | Spherachute 36" (Cd=1.5)           |
| Payload flight mass      | ~1.64 kg (FAA Part 101 Light)      |
| APRS                     | KA7NSR-15 @ 144.390 MHz, 1 W       |

## 4. Data flow

```
raw XLSX  --(xlsx_to_csv.py)-->  data/raw/*.csv
        --(ingest_*.m)-->  D.{trajectory, wind, geiger, multi, arduino}
        --(physics models)-->  sim, sim3d, thermal, power, link, MC
        --(validation_suite)-->  RMSE / R^2 vs flight
        --(viz_*.m)-->  figures/*.png + animation
        --(write_mission_report.m)-->  reports/*.md
```

## 5. Validation philosophy

Every model is benchmarked against an independent measurement:

- **BMP390 baro-altitude vs APRS GPS altitude** -> sensor health check
- **US-1976 temperature vs BMP390 in-situ temperature** -> column truth
- **Pfotzer-Regener model vs GMC-320+ CPM** -> cosmic-ray physics
- **UV/O3 model vs UVA/UVB triad average** -> radiative transfer
- **3D ascent simulation vs APRS trajectory** -> drag/buoyancy fidelity

Numerical results land in `reports/ASCEND_S26_MISSION_REPORT.md` table.

## 6. Reproducibility

- Random seed is fixed (`rng(20260328)`) for Monte Carlo
- Every cached `.mat` includes input config snapshot
- Time bases: trajectory in UTC, geiger/multisensor in MST -> UTC
  conversion handled at ingestion

## 7. Outputs at a glance

After `ASCEND_S26_run()` completes, the following artifacts are produced:

| Path                                                | Type      | Description                                             |
|-----------------------------------------------------|-----------|---------------------------------------------------------|
| `figures/01_trajectory_dashboard.{png,pdf}`         | figure    | 6-panel altitude/velocity/wind/3D summary               |
| `figures/02_atmosphere.{png,pdf}`                   | figure    | US-1976 vs BMP390 column                                |
| `figures/03_science.{png,pdf}`                      | figure    | Pfotzer + UV + PM/CO2 + T/RH                            |
| `figures/04_imu.{png,pdf}`                          | figure    | Gyro / accel / mag dashboards                           |
| `figures/05_simulation.{png,pdf}`                   | figure    | Sim vs flight overlays                                  |
| `figures/06_thermal_power.{png,pdf}`                | figure    | Lumped-C thermal + L91 power budget                     |
| `figures/07_3d_globe.{png,pdf}`                     | figure    | ENU 3D track                                            |
| `figures/08_payload.{png,pdf}`                      | figure    | Mass / power / CG / MOI                                 |
| `figures/09_phase_timeline.{png,pdf}`               | figure    | Annotated mission events                                |
| `figures/10_aerodynamics.{png,pdf}`                 | figure    | Mach, q, Re, energy, N^2                                |
| `figures/11_dispersion.{png,pdf}`                   | figure    | Monte Carlo CEP50/95                                    |
| `figures/12_link_budget.{png,pdf}`                  | figure    | APRS FSPL / SNR / margin                                |
| `figures/13_wind_profile.{png,pdf}`                 | figure    | Hodograph + speed/dir vs altitude                       |
| `figures/11_payload_photos.{png,pdf}`               | figure    | Image gallery of real flight payload (website assets)   |
| `figures/12_payload_3d.{png,pdf,fig}`               | figure    | Programmatic 3-D payload assembly render                |
| `figures/13_website_overlay.{png,pdf}`              | figure    | Public-release UV / radiation / IMU / BMP390 overlay    |
| `figures/14_gforce_burst.{png,pdf,fig}`             | figure    | 3-D g-force vector map at burst (Personfu)              |
| `assets/images/*`                                   | media     | Real payload photos, branding, plots from website repo  |
| `assets/data/spring2026_*.json`                     | data      | Public-release JSON: payload / IMU / radiation / APRS   |
| `reports/ASCEND_S26_summary.txt`                    | text      | Numeric mission summary                                 |
| `reports/ASCEND_S26_MISSION_REPORT.md`              | markdown  | Full graduate-level mission report                      |
| `reports/ASCEND_S26_dashboard.html`                 | HTML      | Self-contained shareable dashboard                      |
| `reports/ASCEND_S26_flight.kml`                     | KML       | Google Earth flight track                               |
| `reports/ASCEND_S26_flight.gpx`                     | GPX 1.1   | Chase-team navigation track                             |
| `data/processed/*.mat`                              | cache     | Trajectories, sims, dynamics, attitude, MC results      |

## 8. Authoring

Designed and authored by *Personfu* for the Phoenix College NASA ASCEND
program, Spring 2026.

---

## Phoenix-1 Payload Showcase (Spring 2026)

The Phoenix College carbon-fiber 3 lb payload is now fully reconstructed in
MATLAB end-to-end.  The single entry point that runs every Fundamental and
Advanced engineering / coding / physics / data-sim module against the
flight payload is:

`matlab
results = payload_showcase();                      % uses simulated flight
results = payload_showcase('csv','asusux.csv');    % uses real V1f log
`

### What it runs (in order)

1. `firmware_decode_csv` - decode the 37-column `asusux.csv` exactly the way
   `HailMaryV1f.ino` writes it, including packed `bno_cal` / `health`
   bytes, scaled-integer GPS, and derived columns.
2. `firmware_simulate_flight` - firmware-in-the-loop synthetic mission used
   when no CSV is provided.
3. `firmware_health_summary` - per-sensor uptime, stale streaks, free-RAM
   trace, phase durations, and re-run impact detection.
4. `viz_payload_cad` / `viz_payload_structural` /
   `viz_payload_thermal_skin` / `viz_payload_aero` /
   `viz_payload_power` / `viz_payload_link_budget` /
   `viz_payload_sensors` - the payload engineering dashboards.
5. `viz_firmware_replay` - 6-panel telemetry replay (altitude with phase
   shading, vertical velocity, accel magnitude with 15 g impact line, UV
   totals, sensor health raster, staleness + free RAM).
6. `viz_payload_dynamics` - tilt, `|omega|`, rotational KE, angular momentum,
   complementary-filter attitude, and roll vs roll-rate phase plane.
7. `viz_payload_vibration` - Welch PSD per axis, `|a|` STFT spectrogram,
   descent-phase acceleration histogram.
8. `viz_payload_kalman` - constant-acceleration Kalman fusion of the BMP
   altitude with the BNO055 vertical accel, exposing the filtered `v_z` state.
9. `viz_payload_allan` - overlapping Allan deviation of the BNO055 gyro
   axes from the ground-phase samples (ARW / bias instability / RRW).
10. `viz_payload_uv_atmo` - Beer-Lambert fit `I(h) = I_inf * exp(-tau * exp(-h/H))`
    to the AS7331 x4 average, plus inter-sensor agreement trace.
11. `viz_payload_montecarlo` - 500-trial parachute / mass / wind / burst-
    altitude descent dispersion with 1 sigma and 2 sigma landing ellipse and
    drift-range histogram.
12. `export_payload_bom` - writes `reports/payload_bom.csv` and
    `reports/payload_engineering.md`.
13. Firmware self-tests - regenerates the 44-byte UBX-CFG-NAV5 Airborne <1g>
    packet and round-trips a GPS fix through the EEPROM pack/unpack helpers.

### Firmware archive

The exact flight firmware is archived under `arduino/HailMaryV1f/` and the
matching MATLAB companion lives in `src/firmware/`:

`
arduino/HailMaryV1f/HailMaryV1f.ino
arduino/docs/V1f_FIRMWARE_REFERENCE.md
src/firmware/firmware_decode_csv.m
src/firmware/firmware_decode_packed.m
src/firmware/firmware_validate_data.m
src/firmware/firmware_flight_phase.m
src/firmware/firmware_detect_impact.m
src/firmware/firmware_health_summary.m
src/firmware/firmware_eeprom_pack.m
src/firmware/firmware_eeprom_unpack.m
src/firmware/firmware_ubx_airborne.m
src/firmware/firmware_simulate_flight.m
`
