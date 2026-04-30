# NASA ASCEND-T-MATS — Phoenix College Spring 2026

> **Full-stack simulation, firmware analysis, and mission reporting suite for the Phoenix College NASA ASCEND Balloon-2 high-altitude flight, integrated with the NASA T-MATS thermodynamic toolbox.**

---

## Table of Contents

1. [Repository Overview](#1-repository-overview)
2. [Sub-Projects at a Glance](#2-sub-projects-at-a-glance)
3. [NASA T-MATS Toolbox](#3-nasa-t-mats-toolbox)
4. [ASCEND Spring 2026 MATLAB Suite](#4-ascend-spring-2026-matlab-suite)
   - 4.1 [Mission Summary](#41-mission-summary)
   - 4.2 [Directory Layout](#42-directory-layout)
   - 4.3 [Quick Start](#43-quick-start)
   - 4.4 [Configuration](#44-configuration)
   - 4.5 [Data Ingestion Pipeline](#45-data-ingestion-pipeline)
   - 4.6 [Physics & Simulation Models](#46-physics--simulation-models)
   - 4.7 [Firmware Archive & Analysis](#47-firmware-archive--analysis)
   - 4.8 [Visualization Suite](#48-visualization-suite)
   - 4.9 [Validation Philosophy](#49-validation-philosophy)
   - 4.10 [Output Artifacts](#410-output-artifacts)
   - 4.11 [Payload Showcase Entry Point](#411-payload-showcase-entry-point)
   - 4.12 [Data Dictionary Summary](#412-data-dictionary-summary)
   - 4.13 [Operations & Launch Timeline](#413-operations--launch-timeline)
   - 4.14 [Reproducibility](#414-reproducibility)
5. [Raw Data Files](#5-raw-data-files)
6. [Sensor Hardware Reference](#6-sensor-hardware-reference)
7. [Software Requirements](#7-software-requirements)
8. [Installation](#8-installation)
9. [Repository File Map](#9-repository-file-map)
10. [License](#10-license)
11. [Authorship & Credits](#11-authorship--credits)

---

## 1. Repository Overview

This repository contains **two integrated codebases**:

| Sub-project | Language | Purpose |
|---|---|---|
| **T-MATS** (`T-MATS/T-MATS-master/`) | MATLAB / Simulink / C | NASA thermodynamic simulation toolbox — turbomachinery, gas dynamics, propulsion |
| **ASCEND-S26** (`matlab_ASCEND_S26/`) | MATLAB | Phoenix College NASA ASCEND Spring 2026 — balloon flight reconstruction, firmware analysis, science data processing |

Both sub-projects are built and tested against **MATLAB R2023b or later** (R2024a recommended). The T-MATS Simulink library additionally requires the Simulink and Aerospace Toolboxes; the ASCEND suite requires only base MATLAB with the Signal Processing Toolbox for spectral analyses.

---

## 2. Sub-Projects at a Glance

```
NASA-ASCEND-T-MATS/
├── T-MATS/
│   └── T-MATS-master/          NASA open-source thermodynamic toolbox (Apache 2.0)
│       ├── Trunk/
│       │   ├── TMATS_Library/  Simulink block library (.slx) + MEX C sources
│       │   ├── TMATS_Support/  HTML block guides, color guides
│       │   ├── TMATS_Examples/ Brayton cycle, AGTF30 turbofan example
│       │   └── TMATS_Tools/    Gas-table builder, NPSS→T-MATS translator
│       └── Resources/
│           └── Testing/        Per-block SIL test beds
└── matlab_ASCEND_S26/          Phoenix College ASCEND simulation suite
    ├── ASCEND_S26_run.m        Master driver
    ├── payload_showcase.m      Payload + firmware showcase driver
    ├── config/                 Mission constants & payload BOM
    ├── src/
    │   ├── io/                 Ingestion, export, and report writers
    │   ├── models/             Physics, atmosphere, simulation, analysis
    │   ├── firmware/           Firmware-in-the-loop MATLAB companions
    │   └── viz/                All visualization functions
    ├── data/
    │   ├── raw/                Flight CSVs (converted from XLSX)
    │   └── processed/          Cached .mat files (git-ignored)
    ├── arduino/
    │   └── HailMaryV1f/        Exact flight firmware (.ino) archive
    ├── assets/
    │   ├── images/             Payload photos and branding
    │   └── data/               Public-release JSON exports
    ├── docs/
    │   ├── DATA_DICTIONARY.md  Column-by-column field reference
    │   ├── OPERATIONS.md       Launch & recovery procedures
    │   └── THEORY.md           Physics derivations and references
    └── reports/                Generated mission reports (git-ignored)
```

---

## 3. NASA T-MATS Toolbox

**T-MATS** (Toolbox for the Modeling and Analysis of Thermodynamic Systems) is a Simulink toolbox developed at NASA Glenn Research Center for the modeling and simulation of thermodynamic systems and their controls.

### Key capabilities

- **Turbomachinery block set** — compressor, turbine, burner, nozzle, inlet, bleed, mixer blocks; each implemented in portable C (MEX) and shipped with a `.tlc` code-generation target for real-time deployment.
- **Multi-loop iterative solver** — Newton-Raphson Jacobian solver for closed-cycle and off-design steady-state convergence.
- **Gas property tables** — a `GasTableBuilder` Cantera-backed GUI generates user-specific thermodynamic tables (2-D and 3-D lookup).
- **NPSS import tool** — `NPSStoTMATS_Tool` maps a Numerical Propulsion System Simulation model into T-MATS block topology automatically.
- **Example systems** — Brayton cycle (`BraytonCycle.slx`) and the AGTF30 turbofan model demonstrate complete propulsion system integration.

### T-MATS Block library (partial)

| Block | File | Description |
|---|---|---|
| Ambient | `Ambient_TMATS.c` | ISA atmosphere with humidity |
| Compressor | `Compressor_TMATS.c` | Map-based compressor with variable geometry |
| Burner | `Burner_TMATS.c` | Combustor with fuel/air ratio and blowout |
| Turbine | `Turbine_TMATS.c` | Map-based turbine, cooling air extraction |
| Nozzle | `Nozzle_TMATS.c` | Convergent/convergent-divergent, choked |
| Bleed | `Bleed_TMATS.c` | Bleed air extraction and re-injection |
| Controller PI | `ControllerPI_TestBed.slx` | Anti-windup proportional-integral controller |

Detailed block documentation lives in `T-MATS/T-MATS-master/Trunk/TMATS_Library/TMATS_Support/*.html` and the generated `BlockGuide.html`.

### T-MATS License

Apache License 2.0 — all equations derived from public sources; all default maps nonproprietary. See `T-MATS/T-MATS-master/` for the complete license text.

---

## 4. ASCEND Spring 2026 MATLAB Suite

### 4.1 Mission Summary

| Parameter | Value |
|---|---|
| Mission | Phoenix College NASA ASCEND — Spring 2026, Balloon-2 |
| APRS Callsign | **KA7NSR-15** |
| Launch UTC | **2026-03-28 16:38:54** |
| Launch site | 32.87533 °N, 112.0495 °W — Maricopa County, AZ (419 m MSL) |
| Burst UTC | 2026-03-28 17:39:36 |
| Burst altitude | **25,145 m (82,497 ft)** |
| Total flight duration | **89 minutes** |
| Ground distance | 57.37 km |
| Peak ascent rate | 7.33 m/s average |
| Peak descent rate | 63.56 mph (28.4 m/s) |
| Landing speed | ~15.1 mph (6.7 m/s) |
| Payload flight mass | ~1.64 kg (FAA Part 101 Light payload) |
| Balloon | Kaymont 1500 g latex, He-filled (~4.2 m³ at launch) |
| Parachute | Spherachute 36″ (Cd = 1.5) |
| Peak cosmic-ray dose | 3.406 µSv/h @ ~63,300 ft (Pfotzer-Regener maximum) |
| Peak CPM | 524 counts/min (GMC-320+) |
| Peak UV (4-sensor sum) | 9,936.5 (relative units) |
| Min temperature | 3 °C (BMP390 in-situ, published rounded) |
| Min pressure | 1,242 Pa |
| Peak g-load | 6.211 g @ 68,761 ft (T+3,844 s) |
| Max ground speed | 93 km/h |

---

### 4.2 Directory Layout

```
matlab_ASCEND_S26/
│
├── ASCEND_S26_run.m            ← MASTER DRIVER (start here)
├── payload_showcase.m          ← Payload + firmware showcase driver
│
├── config/
│   ├── ASCEND_S26_config.m     Mission constants, file paths, balloon/payload specs
│   ├── payload_systems.m       Full hierarchical payload BOM (mass, CG, MOI, sensors)
│   └── payload_engineering.m   Derived structural/thermal/aero engineering numbers
│
├── src/
│   ├── io/
│   │   ├── ingest_trajectory.m     APRS CSV → timetable (171 fixes)
│   │   ├── ingest_windspeed.m      Wind-altitude CSV → timetable
│   │   ├── ingest_geiger.m         GMC-320+ CSV → timetable (3,792 samples)
│   │   ├── ingest_multisensor.m    PMS5003+SCD30 CSV → timetable (4,171 samples)
│   │   ├── ingest_arduino.m        UV+BMP390+IMU CSV → timetable (10,010 samples)
│   │   ├── ingest_website_*.m      JSON importers for public website artifacts
│   │   ├── ingest_all.m            Batch ingestion with .mat cache
│   │   ├── export_kml.m            Google Earth KML flight track writer
│   │   ├── export_gpx.m            GPX 1.1 chase-team navigation track writer
│   │   ├── export_payload_bom.m    CSV + Markdown BOM exporter
│   │   └── write_mission_report.m  Full mission Markdown report writer
│   │
│   ├── models/
│   │   ├── atm_us1976.m            US Standard Atmosphere 1976 (0–86 km)
│   │   ├── compute_ground_track.m  Vincenty inverse geodesic (WGS-84)
│   │   ├── build_wind_profile.m    Wind vector profile interpolator
│   │   ├── simulate_3d_ascent.m    3-DOF wind-coupled RK4 ascent integrator
│   │   ├── analyze_flight_dynamics.m  Dynamic pressure, Mach, Re, N², shear
│   │   ├── model_cosmic_ray.m      Pfotzer-Regener cosmic-ray flux model
│   │   ├── model_uv_ozone.m        Beer-Lambert UV / ozone column model
│   │   ├── igrf13_field.m          IGRF-13 dipole geomagnetic field approximation
│   │   ├── sensor_fusion_attitude.m  Madgwick 9-DOF AHRS filter
│   │   ├── monte_carlo_dispersion.m  500-trial CEP50/95 landing ellipse
│   │   ├── link_budget_aprs.m      144.39 MHz APRS link budget (FSPL, SNR, margin)
│   │   └── detect_flight_events.m  Event detector: release / stratosphere / Armstrong /
│   │                               Pfotzer-Regener maximum / apex / landing
│   │
│   ├── firmware/
│   │   ├── firmware_decode_csv.m       Parse 37-column asusux.csv (exact V1f schema)
│   │   ├── firmware_decode_packed.m    Unpack bno_cal and health packed bytes
│   │   ├── firmware_validate_data.m    Range-clamp validation with prev-value substitution
│   │   ├── firmware_flight_phase.m     Altitude-driven phase state machine
│   │   ├── firmware_detect_impact.m    Impact detector (armed on DESCENT)
│   │   ├── firmware_health_summary.m   Sensor uptime, stale streaks, RAM trace
│   │   ├── firmware_eeprom_pack.m      GPS fix → 24-byte EEPROM packer
│   │   ├── firmware_eeprom_unpack.m    EEPROM bytes → GPS fix unpacker
│   │   ├── firmware_ubx_airborne.m     Regenerate 44-byte UBX-CFG-NAV5 Airborne <1g>
│   │   └── firmware_simulate_flight.m  Firmware-in-the-loop synthetic flight log
│   │
│   └── viz/
│       ├── viz_trajectory.m        6-panel trajectory dashboard
│       ├── viz_atmosphere.m        US-1976 vs BMP390 column comparison
│       ├── viz_science.m           Pfotzer + UV + PM/CO2 + T/RH science panels
│       ├── viz_imu.m               Gyro / accel / magnetometer dashboards
│       ├── viz_3d_globe.m          ENU 3-D trajectory globe
│       ├── viz_simulation.m        Simulation vs flight overlays
│       ├── viz_thermal_power.m     Lumped-capacitance thermal + L91 power budget
│       ├── viz_wind_profile.m      Hodograph + speed/direction vs altitude
│       ├── viz_link_budget.m       APRS FSPL / SNR / link margin vs altitude
│       ├── viz_dispersion.m        Monte Carlo CEP50/95 landing ellipse
│       ├── viz_payload.m           Mass / power / CG / MOI engineering dashboards
│       ├── viz_phase_timeline.m    Annotated mission event timeline
│       ├── viz_aerodynamics.m      Mach, dynamic pressure, Reynolds, N²
│       └── animate_flight.m        MP4 flight animation renderer
│
├── arduino/
│   └── HailMaryV1f/
│       └── HailMaryV1f.ino         Exact as-flown Arduino firmware (archived)
│
├── data/
│   ├── raw/                        Flight CSV files (source of truth)
│   │   ├── parameterization_of_elapsed_time_vs_altitude_for_Balloon_2_Spring_2026_launch__Sheet1.csv
│   │   ├── windspeed_vs_altitude_calculation__Sheet1.csv
│   │   ├── Geiger_counter_data_Spring_2026__Sheet1.csv
│   │   ├── sorted_multisensor_data_Spring_2026__Sheet1.csv
│   │   └── processed_arduino_data_Spring_2026__Sheet1.csv
│   └── processed/                  Cached .mat timetables (auto-generated, git-ignored)
│
├── assets/
│   ├── images/                     Real payload photos and branding artwork
│   └── data/
│       ├── fall2025_payload.json   Prior semester payload reference
│       ├── spring2026_payload.json     Public-release payload metadata JSON
│       ├── spring2026_imu_public.json  Public-release IMU dataset JSON
│       ├── spring2026_radiation_public.json  Public-release radiation JSON
│       ├── spring2026_aprs_track.json  Public-release APRS trajectory JSON
│       └── spring2026_telemetry.json   Public-release combined telemetry JSON
│
├── docs/
│   ├── DATA_DICTIONARY.md          Column-by-column reference for all timetables
│   ├── OPERATIONS.md               Launch day timeline, crew roles, recovery SOP
│   └── THEORY.md                   Full physics derivations and citations
│
├── reports/                        Generated reports (auto-created, git-ignored)
│   ├── ASCEND_S26_summary.txt
│   ├── ASCEND_S26_MISSION_REPORT.md
│   ├── ASCEND_S26_dashboard.html
│   ├── ASCEND_S26_flight.kml
│   ├── ASCEND_S26_flight.gpx
│   └── payload_bom.csv
│
└── figures/                        Generated figures (auto-created, git-ignored)
```

---

### 4.3 Quick Start

```matlab
%% 1. Add MATLAB path and run full pipeline
cd matlab_ASCEND_S26
results = ASCEND_S26_run();           % full pipeline: ingest → simulate → validate → report

%% 2. Optional flags
results = ASCEND_S26_run('NoSim',  true);    % skip dynamic simulation (fast preview)
results = ASCEND_S26_run('Quick',  true);    % skip thermal / power / Monte Carlo
results = ASCEND_S26_run('NoFigs', true);    % suppress figure rendering

%% 3. Render flight animation (requires results struct)
animate_flight(results.D, results.cfg);      % outputs figures/ASCEND_S26_flight.mp4

%% 4. Payload + firmware showcase
results = payload_showcase();                % uses firmware-simulated flight log
results = payload_showcase('csv', 'arduino/HailMaryV1f/asusux.csv'); % real V1f log
```

**Expected run time:** ~3–8 minutes on a modern workstation (Monte Carlo + animation dominate).

---

### 4.4 Configuration

All mission constants are centralized in a single file:

```
matlab_ASCEND_S26/config/ASCEND_S26_config.m
```

Editing this file rewires the entire pipeline. Key configuration sections:

| Section | What it controls |
|---|---|
| `cfg.paths.*` | All directory and file paths (auto-creates `data/processed/`, `figures/`, `reports/`) |
| `cfg.mission.*` | Launch time, callsign, launch site, burst altitude, flight duration |
| `cfg.truth.*` | Ground-truth values from flight: landing coords, burst time, peak dose, max g-load |
| `cfg.balloon.*` | Balloon mass, burst diameter, drag coefficient, helium fill volume, free lift |
| `cfg.payload.*` | Total mass, per-module masses, battery type |
| `cfg.atm.*` | Reference atmosphere selection flag |
| `cfg.sim.*` | Simulation time step, RK4 substeps, Monte Carlo trial count (default: 500) |

**Balloon configuration excerpt:**

```matlab
cfg.balloon.type         = 'Latex sounding (1500 g class)';
cfg.balloon.mass_kg      = 1.500;
cfg.balloon.burst_diam_m = 9.44;       % manufacturer burst diameter
cfg.balloon.cd           = 0.30;       % drag coefficient (sphere)
cfg.balloon.fill_volume_m3 = 4.20;    % at launch
cfg.balloon.free_lift_N  = 9.81*0.85; % nominal free lift
```

---

### 4.5 Data Ingestion Pipeline

```
Raw XLSX (Google Sheets export)
        │
        ├─► xlsx_to_csv.py (tools/)  ──► data/raw/*.csv   (one-time conversion)
        │
        └─► ingest_all.m  ──────────► D struct (in-memory timetables)
                                      │
                                      ├── D.trajectory   171 APRS fixes, UTC-based
                                      ├── D.wind         wind profile vs altitude
                                      ├── D.geiger       3,792 GMC-320+ samples
                                      ├── D.multi        4,171 PMS5003 + SCD30 samples
                                      └── D.arduino      10,010 UV + BMP390 + IMU samples
```

**Cache behavior:** On first run, `ingest_all` processes all CSVs, computes derived columns (vertical velocity, g-load, phase labels, UTC conversion), and saves a `.mat` cache to `data/processed/`. Subsequent runs load the cache instantly unless source CSVs have changed.

**Time-base unification:** All five datasets are on independent clock domains. The ingestion layer converts each to UTC and provides a common `t_s` (seconds since launch) reference column. The geiger and multisensor loggers ran on local Phoenix MST; conversion is handled at ingestion.

---

### 4.6 Physics & Simulation Models

#### US Standard Atmosphere 1976 — `atm_us1976.m`

Implements the full 8-layer piecewise barometric formula valid 0–86 km (extrapolated above). Returns:

| Output | Symbol | Unit |
|---|---|---|
| Temperature | T | K |
| Pressure | P | Pa |
| Density | ρ | kg/m³ |
| Speed of sound | a | m/s |
| Dynamic viscosity | µ | Pa·s |
| Kinematic viscosity | ν | m²/s |

Geometric altitude is converted to geopotential altitude using the WGS-84 Earth radius (6,356,766 m) before layer lookup. Sutherland's law provides viscosity.

#### 3-DOF Wind-Coupled Ascent — `simulate_3d_ascent.m`

RK4 integrator coupling vertical buoyancy and drag with horizontal wind advection. State vector: `[x_E, y_N, z_up, v_E, v_N, v_z]`. Forces:

- **Buoyancy:** `F_b = (ρ_air − ρ_He) · g · V_balloon(h)` with balloon volume expanding as `V(h) = V_0 · (P_0/P(h)) · (T(h)/T_0)` (ideal gas).
- **Drag:** `F_d = 0.5 · ρ_air · Cd · A(h) · |v_rel|²` where `v_rel = v_balloon − v_wind`.
- **Wind:** interpolated from `D.wind` using altitude as the independent variable.

#### Pfotzer-Regener Cosmic-Ray Model — `model_cosmic_ray.m`

Empirical Pfotzer-Regener flux curve fit to the GMC-320+ CPM data:

```
CPM(h) = A · exp(−(h − h_pfotzer)² / (2·σ²)) + C_bg
```

Parameters A, h_pfotzer, σ, and C_bg are fit via nonlinear least squares against the flight data. The model is validated against the observed Pfotzer maximum at ~63,300 ft with a peak dose of 3.406 µSv/h.

#### Beer-Lambert UV / Ozone Model — `model_uv_ozone.m`

Single-layer Beer-Lambert fit to AS7331 UV irradiance vs altitude:

```
I(h) = I_inf · exp(−τ · exp(−h/H))
```

where `I_inf` is the extraterrestrial flux, `τ` is the effective ozone optical depth, and `H` is the ozone scale height. Fit to the 4-sensor UVA/UVB average. Inter-sensor agreement is tracked to flag degraded sensors.

#### IGRF-13 Geomagnetic Field — `igrf13_field.m`

Dipole approximation of the IGRF-13 model for the flight region (Sonoran Desert, ~33°N). Returns:
- Declination (°E)
- Inclination (°)
- Total field intensity (nT)
- North, East, Down components (nT)

Used to validate the LIS3MDL magnetometer readings during the IMU analysis.

#### Madgwick 9-DOF AHRS — `sensor_fusion_attitude.m`

Implements the Madgwick gradient-descent attitude filter fusing:
- ICM-20948 3-axis gyroscope (°/s)
- ICM-20948 3-axis accelerometer (g)
- LIS3MDL 3-axis magnetometer (µT)

Outputs quaternion attitude history, Euler angles (roll/pitch/yaw), and filter convergence diagnostics.

#### Monte Carlo Dispersion — `monte_carlo_dispersion.m`

500 independent trials varying:

| Parameter | Distribution | σ |
|---|---|---|
| Parachute Cd | Normal | ±5% |
| Payload mass | Normal | ±3% |
| Burst altitude | Normal | ±500 m |
| Wind speed (each layer) | Normal | ±15% |
| Wind direction (each layer) | Normal | ±10° |

Outputs: CEP50 and CEP95 landing ellipse semi-axes and orientation, drift-range histogram, and 2-sigma landing polygon overlaid on a map.

#### APRS Link Budget — `link_budget_aprs.m`

Full Friis transmission link budget for 144.390 MHz KA7NSR-15:

| Parameter | Value |
|---|---|
| TX power | 1 W (30 dBm) |
| TX antenna gain | 0 dBd (quarter-wave whip) |
| RX antenna gain | 3 dBd (j-pole at digipeater) |
| FSPL formula | `20·log10(d) + 20·log10(f) − 147.55` |
| Required SNR | 10 dB (AX.25 1200 baud) |
| System noise figure | 6 dB |

Computes link margin vs altitude, identifies first-acquisition range, and flags packet-loss windows during descent below ridge line.

#### Flight Event Detection — `detect_flight_events.m`

Automatically labels the following events from the trajectory timetable:

| Event | Detection criterion |
|---|---|
| Release | First APRS fix; `vz > 1 m/s` |
| Stratosphere entry | Altitude crosses 11,000 m MSL |
| Armstrong limit | Altitude crosses 19,202 m (63,000 ft) — water-body boiling point |
| Pfotzer-Regener maximum | Peak CPM in geiger timetable |
| Apex / burst | `vz` transitions from positive to negative |
| Nominal landing | Last APRS fix; `vz < 1 m/s` |

#### Aerodynamic Analysis — `analyze_flight_dynamics.m`

Derives the following from the trajectory and US-1976 atmosphere:

| Quantity | Symbol | Description |
|---|---|---|
| Dynamic pressure | q | `0.5 · ρ · v²` — structural load |
| Mach number | M | `|v| / a` — compressibility regime |
| Reynolds number | Re | `ρ · |v| · D / µ` — viscous regime |
| Total mechanical energy | E | `KE + PE` per unit mass |
| Brunt–Väisälä frequency | N² | Atmospheric static stability |
| Wind shear | ∂v/∂z | Layer-by-layer wind gradient |

---

### 4.7 Firmware Archive & Analysis

The **exact as-flown Arduino firmware** is archived at:

```
arduino/HailMaryV1f/HailMaryV1f.ino
```

The firmware runs at a **500 ms sample period** (`writeInterval`) and logs 37 columns to `asusux.csv` on the onboard SD card. The MATLAB firmware companion functions in `src/firmware/` implement the same logic in pure MATLAB so that flight data and simulated data are interchangeable.

#### Firmware CSV Schema (37 columns)

| Column group | Columns | Notes |
|---|---|---|
| Timing | `elapsed_ms`, `sample_n` | Milliseconds since boot; sample counter |
| GPS | `lat`, `lon`, `alt_m`, `sats`, `hdop`, `fix` | Scaled integers packed for EEPROM |
| BMP390 | `pres_pa`, `temp_c`, `alt_bmp_m` | Barometric altitude |
| ICM-20948 Gyro | `gx`, `gy`, `gz` | °/s, raw scaled |
| ICM-20948 Accel | `ax`, `ay`, `az` | g, raw scaled |
| ICM-20948 Mag | `mx`, `my`, `mz` | µT (via LIS3MDL companion) |
| UV | `uva1..4`, `uvb1..4`, `uvc1..4` | mW/cm² per sensor triad |
| Derived | `vz_ms`, `az_g`, `flight_phase` | Firmware-computed |
| Packed bytes | `bno_cal`, `health` | Bitfield: sensor calibration / health flags |
| RAM | `free_ram` | Bytes free on Arduino heap |

#### EEPROM Pack/Unpack

`firmware_eeprom_pack.m` and `firmware_eeprom_unpack.m` implement the 24-byte EEPROM encoding used to store the last known GPS fix across power cycles (critical for cold-start recovery after battery swap). The round-trip is validated as part of `payload_showcase`.

#### UBX-CFG-NAV5 Airborne Mode

`firmware_ubx_airborne.m` regenerates the exact 44-byte UBX-CFG-NAV5 packet sent by the firmware to the u-blox MAX-M8Q to enable **Airborne <1g> dynamic model** (required for GPS to function above 12 km; standard pedestrian/automotive modes report 0 altitude above this ceiling). The packet is byte-for-byte verified against the u-blox M8 protocol specification (UBX-18010854).

---

### 4.8 Visualization Suite

All figures are saved to `figures/` as both `.png` and `.pdf`. Run `ASCEND_S26_run()` to generate all; individual `viz_*.m` functions may be called standalone with a loaded results struct.

| Figure index | Function | Content |
|---|---|---|
| 01 | `viz_trajectory` | 6-panel: altitude/time, vertical velocity, ground speed, course, 2-D ground track, 3-D altitude-colored track |
| 02 | `viz_atmosphere` | US-1976 T/P/ρ column vs BMP390 in-situ measurements; sensor health check |
| 03 | `viz_science` | Pfotzer cosmic-ray flux + model fit; UV irradiance (4-sensor); PM2.5/PM10 vs altitude; CO2, T, RH profiles |
| 04 | `viz_imu` | Gyroscope (x/y/z °/s); accelerometer (x/y/z g + magnitude); magnetometer (x/y/z µT); derived roll/pitch/yaw |
| 05 | `viz_simulation` | Sim vs flight altitude overlay; velocity residuals; energy budget |
| 06 | `viz_thermal_power` | Lumped-capacitance thermal model: external skin, internal air, sensor nodes; L91 battery coulomb-counting |
| 07 | `viz_3d_globe` | ENU 3-D trajectory colored by phase, with burst and landing markers |
| 08 | `viz_payload` | Mass budget pie; power budget; CG position vs mass; principal MOI eigenvalues |
| 09 | `viz_phase_timeline` | Timeline bar with annotated events (release, stratosphere, Armstrong, Pfotzer, apex, landing) |
| 10 | `viz_aerodynamics` | Dynamic pressure (Pa); Mach number; Reynolds number; total energy; Brunt–Väisälä N²; wind shear |
| 11 | `viz_dispersion` | Monte Carlo 500-trial scatter; CEP50/CEP95 ellipses; drift-range histogram |
| 12 | `viz_link_budget` | APRS FSPL vs altitude; SNR vs altitude; link margin (dB); packet acquisition/loss windows |
| 13 | `viz_wind_profile` | Wind hodograph (vE vs vN); speed and direction vs altitude |
| — | `animate_flight` | MP4 animation: real-time altitude/velocity trace with phase shading and APRS fix markers |

---

### 4.9 Validation Philosophy

Every physics model is independently benchmarked against flight data. No free parameters are tuned without physical justification.

| Model | Validation dataset | Metric |
|---|---|---|
| US-1976 temperature | BMP390 in-situ temperature column | RMSE, R² |
| US-1976 pressure | BMP390 pressure column | RMSE, R² |
| 3-D ascent simulation | APRS GPS trajectory | RMSE altitude, RMSE ground track |
| Pfotzer-Regener model | GMC-320+ CPM vs altitude | RMSE CPM, peak altitude error |
| Beer-Lambert UV model | AS7331 4-sensor average | RMSE irradiance, inter-sensor σ |
| IGRF-13 dipole | LIS3MDL total field intensity | % deviation from IGRF |
| Madgwick AHRS | Static ground epoch (known level) | Roll/pitch bias, yaw drift rate |
| EEPROM pack/unpack | Round-trip test (no hardware) | Bit-exact match |
| UBX-CFG-NAV5 | Known-good packet (u-blox datasheet) | Byte-exact match |

Numerical validation results are written to `reports/ASCEND_S26_MISSION_REPORT.md` automatically.

---

### 4.10 Output Artifacts

After `ASCEND_S26_run()` completes:

| Path | Type | Description |
|---|---|---|
| `figures/01_trajectory_dashboard.{png,pdf}` | Figure | 6-panel altitude / velocity / ground track |
| `figures/02_atmosphere.{png,pdf}` | Figure | US-1976 vs BMP390 column |
| `figures/03_science.{png,pdf}` | Figure | Pfotzer + UV + PM/CO2 + T/RH |
| `figures/04_imu.{png,pdf}` | Figure | Gyro / accel / mag dashboards |
| `figures/05_simulation.{png,pdf}` | Figure | Sim vs flight overlays |
| `figures/06_thermal_power.{png,pdf}` | Figure | Lumped-capacitance thermal + L91 power |
| `figures/07_3d_globe.{png,pdf}` | Figure | ENU 3-D trajectory |
| `figures/08_payload.{png,pdf}` | Figure | Mass / power / CG / MOI |
| `figures/09_phase_timeline.{png,pdf}` | Figure | Annotated mission event timeline |
| `figures/10_aerodynamics.{png,pdf}` | Figure | Mach, q, Re, N², shear |
| `figures/11_dispersion.{png,pdf}` | Figure | Monte Carlo CEP50/95 |
| `figures/12_link_budget.{png,pdf}` | Figure | APRS FSPL / SNR / margin |
| `figures/13_wind_profile.{png,pdf}` | Figure | Hodograph + speed/dir vs altitude |
| `figures/ASCEND_S26_flight.mp4` | Video | Full flight animation |
| `reports/ASCEND_S26_summary.txt` | Text | Numeric mission summary |
| `reports/ASCEND_S26_MISSION_REPORT.md` | Markdown | Full graduate-level mission report |
| `reports/ASCEND_S26_dashboard.html` | HTML | Self-contained shareable dashboard |
| `reports/ASCEND_S26_flight.kml` | KML | Google Earth flight track |
| `reports/ASCEND_S26_flight.gpx` | GPX 1.1 | Chase-team navigation track |
| `reports/payload_bom.csv` | CSV | Bill of materials |
| `reports/payload_engineering.md` | Markdown | Structural / thermal / aero engineering summary |
| `data/processed/*.mat` | Cache | Timetables, sims, dynamics, attitude, MC results |

---

### 4.11 Payload Showcase Entry Point

`payload_showcase.m` runs every engineering analysis module against the flight payload in sequence. It accepts either a real V1f CSV or generates a synthetic firmware-simulated log.

```matlab
results = payload_showcase();                          % synthetic log
results = payload_showcase('csv', 'path/to/asusux.csv'); % real flight log
```

**Execution order:**

1. `firmware_decode_csv` — parse 37-column asusux.csv (packed bytes, scaled-integer GPS, derived columns)
2. `firmware_simulate_flight` — generate synthetic log if no CSV provided (500 ms period, altitude-driven phase state machine)
3. `firmware_health_summary` — per-sensor uptime %, stale-streak detection, free-RAM trace, phase durations, impact detection re-run
4. Payload engineering dashboards — CAD render, structural, thermal skin, aerodynamics, power, link budget, sensor summary
5. `viz_firmware_replay` — 6-panel telemetry replay: altitude (phase-shaded), vertical velocity, accel magnitude (15 g impact line), UV totals, sensor health raster, staleness + free RAM
6. `viz_payload_dynamics` — tilt angle, `|ω|`, rotational KE, angular momentum, complementary-filter attitude, roll vs roll-rate phase plane
7. `viz_payload_vibration` — Welch PSD per axis, `|a|` STFT spectrogram, descent-phase acceleration histogram
8. `viz_payload_kalman` — constant-acceleration Kalman fusion of BMP390 barometric altitude with BNO055 vertical accelerometer; filtered `v_z` state
9. `viz_payload_allan` — overlapping Allan deviation of BNO055 gyro axes from ground-phase: ARW / bias instability / RRW
10. `viz_payload_uv_atmo` — Beer-Lambert fit to AS7331 4-sensor average; inter-sensor agreement trace
11. `viz_payload_montecarlo` — 500-trial descent dispersion; 1σ and 2σ landing ellipses; drift-range histogram
12. `export_payload_bom` — write `reports/payload_bom.csv` and `reports/payload_engineering.md`
13. Firmware self-tests — UBX-CFG-NAV5 packet regeneration; EEPROM pack/unpack round-trip

---

### 4.12 Data Dictionary Summary

Full column-by-column documentation is in [`docs/DATA_DICTIONARY.md`](matlab_ASCEND_S26/docs/DATA_DICTIONARY.md). Summary:

#### D.trajectory — 171 APRS fixes (KA7NSR-15)

| Field | Unit | Notes |
|---|---|---|
| t (RowTime) | datetime UTC | First fix: 2026-03-28 16:38:54 |
| t_s | s | Seconds since launch |
| lat / lon | °N / °E | WGS-84 |
| alt_m / alt_ft | m / ft MSL | GPS WGS-84 |
| gs_mph | mph | APRS-reported ground speed |
| course_deg | ° | Course over ground |
| vz_ms | m/s | Derived dh/dt |
| az_g | g | Derived dv_z/dt |
| phase | string | launch / ascent / apex / descent / landed |

#### D.geiger — 3,792 GMC-320+ samples

| Field | Unit | Notes |
|---|---|---|
| t | datetime UTC | Converted from Phoenix MST |
| cpm | counts/min | Raw tube count |
| dose_uSvph | µSv/h | CPM × tube conversion factor |

#### D.multi — 4,171 PMS5003 + SCD30 samples

| Field | Unit | Notes |
|---|---|---|
| pm25 / pm100 | µg/m³ | Particle mass concentrations |
| co2_ppm | ppm | NDIR CO₂ |
| temp_C / rh_pct | °C / % | SHT31 internal to SCD30 |

#### D.arduino — 10,010 UV + BMP390 + ICM-20948 + LIS3MDL samples

| Field | Unit | Notes |
|---|---|---|
| uva1..4 / uvb1..4 / uvc1..4 | mW/cm² | Per-sensor triad |
| UVA_mWcm2 / UVB_mWcm2 | mW/cm² | 4-sensor mean |
| pres_pa / temp_c / alt_bmp_m | Pa / °C / m | BMP390 |
| gx / gy / gz | °/s | ICM-20948 gyro |
| ax / ay / az | g | ICM-20948 accel |

---

### 4.13 Operations & Launch Timeline

Full procedures in [`docs/OPERATIONS.md`](matlab_ASCEND_S26/docs/OPERATIONS.md). Key timeline:

| T-time | Event |
|---|---|
| T−180 min | Arrive at 32.87533°N, 112.0495°W |
| T−90 min | Begin He fill (~4.2 m³ at 99.99% purity) |
| T−30 min | Power on all loggers (Geiger, multisensor, Arduino UV/IMU) |
| T−15 min | APRS beacon active (60-second interval) |
| T−5 min | FAA courtesy notification |
| **T = 0** | **Release — 16:38:54 UTC** |
| T+60 min | Expected apex (25,145 m) |
| T+89 min | Observed apex / burst |
| T+~150 min | Expected impact (dispersion median) |

**Recovery:** Drive to Monte Carlo median landing zone; final 5 km on 144.39 MHz handheld. Visual-spot orange/white box. Power off all loggers before transport. Secure SD card and EEPROM.

**Post-flight:** Run `ASCEND_S26_run()` to generate full report. Archive `data/raw/` to OneDrive. File post-mission report with NASA ASCEND program.

---

### 4.14 Reproducibility

- Random seed is **fixed** (`rng(20260328)`) at the top of every Monte Carlo and simulation run.
- Every cached `.mat` file includes a snapshot of the `cfg` struct used to generate it.
- All UTC conversions are explicit; no implicit local-time dependencies.
- The firmware simulation uses `rng(0)` by default; override with `opts.seed`.
- MATLAB version pinned: **R2023b** (tested; R2024a recommended).

---

## 5. Raw Data Files

| File | Source instrument | Samples | Time base |
|---|---|---|---|
| `parameterization_of_elapsed_time_vs_altitude_for_Balloon_2_Spring_2026_launch__Sheet1.csv` | APRS / aprs.fi | 171 fixes | UTC |
| `windspeed_vs_altitude_calculation__Sheet1.csv` | APRS-derived wind segments | ~140 rows | UTC |
| `Geiger_counter_data_Spring_2026__Sheet1.csv` | GMC-320+ geiger counter | 3,792 rows | Local MST |
| `sorted_multisensor_data_Spring_2026__Sheet1.csv` | PMS5003 + SCD30 on Arduino MEGA | 4,171 rows | Local MST |
| `processed_arduino_data_Spring_2026__Sheet1.csv` | UV triads + BMP390 + ICM-20948 + LIS3MDL | 10,010 rows | Elapsed ms |

All files are UTF-8 CSV. The `tools/xlsx_to_csv.py` script was used for initial conversion from Google Sheets XLSX export.

---

## 6. Sensor Hardware Reference

| Sensor | Module | Measurand | Interface | Altitude limit |
|---|---|---|---|---|
| **u-blox MAX-M8Q** | APRS tracker | GPS position, altitude, ground speed | NMEA UART | 50,000 m (Airborne <1g> mode) |
| **BMP390** | Arduino stack | Pressure, temperature, barometric altitude | I²C 0x77 | No limit (pressure → 0) |
| **ICM-20948** | Arduino stack | 3-axis gyro, 3-axis accel | I²C/SPI | No mechanical limit |
| **LIS3MDL** | Arduino stack | 3-axis magnetometer | I²C 0x1C | No limit |
| **AS7331** ×4 | Arduino stack | UVA, UVB, UVC spectral irradiance | I²C | No limit |
| **PMS5003** | Multisensor | PM0.3–PM10 particle counts | UART | Degraded performance <50 mbar (~20 km) |
| **SCD30** | Multisensor | CO₂ (NDIR), temperature, RH | I²C 0x61 | Spec: 0–50,000 ppm CO₂ |
| **GMC-320+** | Geiger module | CPM, µSv/h | USB serial log | No limit |
| **Byonics MicroTrak RTG** | APRS tracker | 144.390 MHz AX.25 APRS | RF | No limit |

---

## 7. Software Requirements

### ASCEND Suite

| Requirement | Minimum | Recommended |
|---|---|---|
| MATLAB | R2022b | R2024a |
| Signal Processing Toolbox | Required for Welch PSD, STFT, Allan deviation | — |
| Statistics and Machine Learning Toolbox | Optional (Monte Carlo CI calculations) | Recommended |
| Mapping Toolbox | Optional (KML/GPX export enhanced) | Optional |
| Parallel Computing Toolbox | Optional (Monte Carlo speedup) | Recommended |

### T-MATS (in `T-MATS/T-MATS-master/`)

| Requirement | Notes |
|---|---|
| MATLAB + Simulink | Required |
| Aerospace Toolbox | Required for some example models |
| Stateflow | Required for control logic blocks |
| MATLAB Coder | Required for MEX compilation |
| Cantera | Optional — only for `GasTableBuilder` |

---

## 8. Installation

### Clone the repository

```bash
git clone https://github.com/Personfu/NASA-ASCEND-T-MATS.git
cd NASA-ASCEND-T-MATS
```

### Set up the ASCEND suite

```matlab
% In MATLAB:
cd matlab_ASCEND_S26
% No toolbox installation required beyond base MATLAB + Signal Processing Toolbox
% Run the master driver:
results = ASCEND_S26_run();
```

### Set up T-MATS

```matlab
cd T-MATS/T-MATS-master
% Follow installation instructions in Trunk/UsersManual.pdf
% Install the Simulink library:
run('Trunk/TMATS_install.m')
```

### Convert raw XLSX (if re-exporting from Google Sheets)

```bash
pip install openpyxl
python tools/xlsx_to_csv.py --input path/to/export.xlsx --outdir matlab_ASCEND_S26/data/raw/
```

---

## 9. Repository File Map

```
NASA-ASCEND-T-MATS/
├── .gitattributes
├── .gitignore
├── README.md                          ← this file
├── T-MATS/
│   └── T-MATS-master/                 NASA T-MATS thermodynamic toolbox (Apache 2.0)
└── matlab_ASCEND_S26/                 Phoenix College ASCEND Spring 2026 suite
    ├── ASCEND_S26_run.m
    ├── payload_showcase.m
    ├── README.md                      ← detailed ASCEND-specific README
    ├── config/
    │   ├── ASCEND_S26_config.m
    │   ├── payload_systems.m
    │   └── payload_engineering.m
    ├── src/
    │   ├── io/                        (12 functions)
    │   ├── models/                    (14 functions)
    │   ├── firmware/                  (11 functions)
    │   └── viz/                       (14 functions + animate_flight)
    ├── arduino/
    │   └── HailMaryV1f/
    │       └── HailMaryV1f.ino
    ├── data/
    │   ├── raw/                       (5 CSV files — flight source of truth)
    │   └── processed/                 (auto-generated .mat cache — git-ignored)
    ├── assets/
    │   ├── images/
    │   └── data/                      (6 JSON files — public release artifacts)
    ├── docs/
    │   ├── DATA_DICTIONARY.md
    │   ├── OPERATIONS.md
    │   └── THEORY.md
    ├── reports/                        (auto-generated — git-ignored)
    └── figures/                        (auto-generated — git-ignored)
```

---

## 10. License

| Component | License |
|---|---|
| **T-MATS** (`T-MATS/T-MATS-master/`) | Apache License 2.0 — © NASA |
| **ASCEND Suite** (`matlab_ASCEND_S26/`) | MIT License — © 2026 Personfu / Phoenix College NASA ASCEND |

---

## 11. Authorship & Credits

**ASCEND Simulation Suite** designed and authored by **Personfu** — Senior Engineering / Simulation Architect, Phoenix College NASA ASCEND program, Spring 2026.

**T-MATS** developed by NASA Glenn Research Center on behalf of the NASA Aviation Safety Program's Vehicle Systems Safety Technologies (VSST) project. All T-MATS equations derived from public sources; all default maps and constants nonproprietary.

**Flight data** captured by the Phoenix College NASA ASCEND Spring 2026 team during Balloon-2 mission (KA7NSR-15), launched 2026-03-28.

---

*For questions, open an issue on this repository or contact the Phoenix College NASA ASCEND team.*
