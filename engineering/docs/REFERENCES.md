# References & Data Provenance

Every model in the Near-Space Engineering Toolkit is derived from **public and
government sources**. Nothing here is proprietary. This file is the annotated
bibliography; inline citations in the source code point back to these entries.

The toolkit follows the same provenance philosophy as NASA **T-MATS**, whose
release statement reads: *"All T-MATS equations were developed from public
sources and all default maps and constants … are nonproprietary and available
to the public"* (NASA TM-2014-216638).

---

## 1. Standard atmosphere & Earth model

- **U.S. Standard Atmosphere, 1976.** NOAA-S/T 76-1562. National Oceanic and
  Atmospheric Administration (NOAA), National Aeronautics and Space
  Administration (NASA), United States Air Force (USAF). U.S. Government
  Printing Office, Washington, D.C., October 1976.
  *Used for:* `atmosphere.py` (full 7-layer model), the frozen constants
  R\* = 8.31432 J·mol⁻¹·K⁻¹, M₀ = 0.0289644 kg·mol⁻¹, g₀ = 9.80665 m·s⁻²,
  r₀ = 6 356 766 m, and the Sutherland viscosity law (Eq. 51).
- **NOAA / NWS — Standard Atmosphere documentation and rawinsonde program.**
  *Used for:* radiosonde ascent-rate practice (~5 m/s nominal) and wind-profile
  data sourcing.
- **NIMA TR8350.2, *Department of Defense World Geodetic System 1984*** (WGS-84),
  3rd ed., 2000. *Used for:* Earth ellipsoid parameters in `constants.py` and
  the great-circle / destination-point math in `flight.py`.

## 2. Fundamental constants & gas properties

- **NIST CODATA 2018**, *Recommended Values of the Fundamental Physical
  Constants*, https://physics.nist.gov/cuu/Constants/.
  *Used for:* universal gas constant, Avogadro, Boltzmann, Stefan-Boltzmann,
  speed of light in `constants.py`.
- **NIST Chemistry WebBook, SRD 69**, https://webbook.nist.gov/chemistry/.
  *Used for:* molar masses of He, H₂, dry air, H₂O.

## 3. Balloon buoyancy & ascent

- **Gallice, A., Wienhold, F.G., Hoyle, C.R., Immler, F., Peter, T. (2011).**
  "Modeling the ascent of sounding balloons: derivation of the vertical air
  motion." *Atmospheric Measurement Techniques*, 4, 2235–2253.
  *Used for:* the drag-balance ascent-velocity formulation and Reynolds-regime
  drag coefficient (`balloon.py`).
- **Kaymont Consolidated Industries — sounding-balloon technical data**
  (burst diameter, balloon mass, recommended free lift).
  *Used for:* `data/balloons_burst_diameter.csv` and `BALLOON_CATALOG`.
- **Totex / Hwoyee meteorological balloon specifications** (public datasheets).
- **NOAA NWS Radiosonde Replacement System (RRS)** engineering documentation.
  *Used for:* nominal free-lift / ascent-rate cross-checks.

## 4. Descent & recovery

- **Knacke, T.W. (1992).** *Parachute Recovery Systems Design Manual.*
  NWC TP 6575, Naval Weapons Center, China Lake, CA (public release).
  *Used for:* canopy drag coefficients and terminal-velocity methodology
  (`descent.py`, `data/parachutes.csv`).
- **Vendor specifications:** Rocketman Enterprises, SkyAngle/B2 Rocketry,
  Spherachute (public parachute dimensions and Cd guidance).

## 5. Thermal control

- **NASA SP-8055 (1971),** *Prediction of Temperature Variation in
  Electronic Equipment* / spacecraft thermal design monographs.
- **Gilmore, D.G. (ed.) (2002).** *Spacecraft Thermal Control Handbook,
  Volume I: Fundamental Technologies.* The Aerospace Press / AIAA.
  *Used for:* radiative balance, solar absorptivity α and IR emissivity ε of
  surface finishes, view-factor approach (`thermal.py`).
- **Kopp, G. & Lean, J.L. (2011).** "A new, lower value of total solar
  irradiance," *Geophys. Res. Lett.*, 38, L01706 — TSI = 1361 W·m⁻².
  *Used for:* `SOLAR_CONSTANT` (NASA SORCE/TIM).
- **NASA Earth Fact Sheet** (planetary Bond albedo ≈ 0.30, OLR ≈ 240 W·m⁻²).
- **Incropera, F.P. & DeWitt, D.P.,** *Fundamentals of Heat and Mass Transfer.*
  *Used for:* free-convection Nusselt correlation in `thermal.py`.

## 6. Communications / RF

- **Bruninga, R. (WB4APR).** *APRS Protocol Reference v1.0.1*, Tucson Amateur
  Packet Radio (TAPR), 2000. *Used for:* APRS framing context (`comms.py`).
- **ITU-R Recommendation P.525**, *Calculation of free-space attenuation.*
  *Used for:* Friis path-loss equation.
- **ITU-R Recommendation P.834**, *Effects of tropospheric refraction.*
  *Used for:* 4/3-Earth effective-radius radio horizon.
- **ARRL Antenna Book / The ARRL Handbook** — VHF/UHF propagation and radio
  horizon. *Used for:* link-budget conventions.
- **FCC 47 CFR Part 97** (Amateur Radio Service) — operating context for
  balloon telemetry; **Arizona Near Space Research (ANSR)** operating practice
  on the 2 m band (144.39 MHz US APRS; 144.34 MHz regional balloon use).

## 7. Flight prediction

- **Cambridge University Spaceflight (CUSF)** Landing Predictor — open
  methodology for layered-wind ascent/burst/descent trajectory integration.
- **NOAA Global Forecast System (GFS)** gridded wind forecasts — operational
  wind source for real predictions (the toolkit accepts any layered profile).
- **Williams, E.,** *Aviation Formulary* — spherical-Earth navigation formulae
  (destination point, great-circle distance) used in `flight.py`.

## 8. Regulatory

- **14 CFR Part 101**, *Moored Balloons, Kites, Amateur Rockets, and Unmanned
  Free Balloons*, Subpart D. U.S. Federal Aviation Administration.
- **FAA Advisory Circular AC 101-1**, unmanned free-balloon operations.
  *Used for:* `docs/FAA_PART101.md` compliance summary.

## 9. T-MATS heritage

- **Chapman, J.W., Lavelle, T.M., May, R.D., Litt, J.S., Guo, T.-H. (2014).**
  *Toolbox for the Modeling and Analysis of Thermodynamic Systems (T-MATS)
  User's Guide.* NASA/TM—2014-216638. NASA Glenn Research Center.
  *(Included in this repo at `T-MATS/T-MATS/Trunk/`.)*
- **NASA NPSS** (Numerical Propulsion System Simulation) — component-map and
  station-numbering conventions referenced in `docs/07_TMATS_BRIDGE.md`.
- **SAE ARP755** — gas-turbine engine station-numbering nomenclature.

---

### A note on numeric reproducibility

The standard-atmosphere implementation deliberately uses the *frozen 1976*
constants so its output matches the **published USSA-1976 tables to < 0.001 %**
(verified in `tests/test_validation.py`). Modern CODATA constants are used
everywhere the "true" present-day value matters (radiation, gas density).
