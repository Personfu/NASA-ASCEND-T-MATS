# Near-Space Engineering Toolkit (`engineering/`)

> **A physics-first, fully-runnable engineering analysis suite for high-altitude
> balloon (HAB) payloads — inspired by [Arizona Near Space Research
> (ANSR)](http://www.ansr.org/) practice and built for the NASA **ASCEND**
> high-altitude balloon program. Every model is grounded in public/government
> sources (NASA, NOAA, NIST, USAF, FAA) and validated against published
> reference data.**

This module sits alongside the NASA **T-MATS** thermodynamic toolbox and the
Phoenix College **ASCEND-S26** flight suite. Where T-MATS models the
thermodynamics of *turbomachinery*, this toolkit applies the same first-law,
energy-balance, and numerical-solver methods to the thermodynamics and flight
mechanics of a *near-space balloon payload*. See
[`docs/07_TMATS_BRIDGE.md`](docs/07_TMATS_BRIDGE.md) for the explicit mapping.

---

## Why this exists

A NASA ASCEND / ANSR balloon flight is a complete aerospace systems-engineering
problem in miniature: atmospheric modeling, lighter-than-air buoyancy,
aerodynamics, thermal control, RF link design, trajectory prediction, recovery
safety, and regulatory compliance. This toolkit turns each of those into a
small, auditable, reproducible model so a student team can **size a flight,
predict where it lands, and prove it is safe and legal — before filling a single
balloon.**

Everything here runs with **`python3` + `numpy` + `matplotlib`** (no MATLAB
license, no Simulink, no internet). Run the validation suite and you reproduce
the U.S. Standard Atmosphere 1976 tables to better than 0.1 %.

---

## What's inside

```
engineering/
├── nearspace/                 Python package (pure-physics models)
│   ├── constants.py           NIST/USSA-1976/WGS-84 constants (every value cited)
│   ├── atmosphere.py          U.S. Standard Atmosphere 1976 (0–86 km)
│   ├── lift_gas.py            He/H2 buoyancy & ideal-gas thermodynamics
│   ├── balloon.py             latex-balloon ascent + burst prediction
│   ├── descent.py             parachute terminal-velocity descent & recovery
│   ├── thermal.py             payload radiative/convective energy balance
│   ├── comms.py               APRS / 2 m VHF link budget & radio horizon
│   └── flight.py              end-to-end trajectory prediction (layered winds)
├── examples/                  six runnable studies that emit figures/
├── tests/                     validation suite (atmosphere table + sanity)
├── data/                      reference tables (balloons, parachutes, atmosphere)
├── docs/                      deep, cited engineering notes (one per subsystem)
└── figures/                   generated plots (regenerate with examples/)
```

---

## Quick start

```bash
cd engineering
python3 -m pip install -r requirements.txt        # numpy + matplotlib

# 1) prove the physics is right (reproduces USSA-1976 tables)
python3 tests/test_validation.py

# 2) generate every figure (atmosphere, ascent, descent, thermal, RF, flight)
cd examples
for f in 0*.py; do python3 "$f"; done
```

Outputs land in `engineering/figures/`. Each example also prints a concise
engineering summary to the console (burst altitude, landing velocity, link
margin, predicted range, …).

---

## Headline results (defaults: Kaymont-1500, He, 1 kg payload, Phoenix AZ)

| Quantity | Model output | Cross-check |
|---|---|---|
| Burst altitude | **34.1 km** | Kaymont-1500 datasheet ≈ 35 km |
| Mean ascent rate | **~5–8 m/s** (free-lift dependent) | NWS radiosonde nominal ≈ 5 m/s |
| Landing velocity (60 in chute) | **3.3 m/s** | Knacke / Part 101 "gentle" |
| Impact energy (1.2 kg) | **6.5 J** | well under hazard thresholds |
| Radio horizon at 30 km | **727 km** | 4/3-Earth VHF LOS |
| APRS link margin @ 300 km | **+21.8 dB** | closes with margin |
| Payload interior @ 30 km | **−33 °C** (2 W, α/ε finish) | survivable with heater budget |

The atmosphere model reproduces the **official USSA-1976 pressure table to
< 0.001 %** at every layer boundary — see `tests/test_validation.py`.

---

## Subsystem documentation

| Doc | Topic | Primary sources |
|---|---|---|
| [`docs/00_OVERVIEW.md`](docs/00_OVERVIEW.md) | systems-engineering overview | NASA SE Handbook |
| [`docs/01_ATMOSPHERE.md`](docs/01_ATMOSPHERE.md) | USSA-1976 derivation & validation | NOAA/NASA/USAF |
| [`docs/02_BALLOON_ASCENT.md`](docs/02_BALLOON_ASCENT.md) | buoyancy, ascent rate, burst | Gallice 2011, Kaymont |
| [`docs/03_DESCENT_RECOVERY.md`](docs/03_DESCENT_RECOVERY.md) | parachute descent & recovery | Knacke NWC TP 6575 |
| [`docs/04_THERMAL.md`](docs/04_THERMAL.md) | payload thermal balance | NASA SP-8055, Gilmore |
| [`docs/05_COMMS_APRS.md`](docs/05_COMMS_APRS.md) | APRS/VHF link budget | APRS spec, ITU-R P.525 |
| [`docs/06_FLIGHT_PREDICTION.md`](docs/06_FLIGHT_PREDICTION.md) | trajectory & wind drift | CUSF, NOAA GFS |
| [`docs/07_TMATS_BRIDGE.md`](docs/07_TMATS_BRIDGE.md) | T-MATS ⇄ balloon methods | NASA TM-2014-216638 |
| [`docs/FAA_PART101.md`](docs/FAA_PART101.md) | regulatory compliance | 14 CFR Part 101 |
| [`docs/REFERENCES.md`](docs/REFERENCES.md) | full annotated bibliography | — |

---

## Design principles

1. **Every constant is cited.** Open `constants.py`; each value names its source.
2. **Validate against published data.** The atmosphere matches the official
   tables; the integrated models are sanity-checked against known ANSR/ASCEND
   flight ranges in `tests/`.
3. **No black boxes.** Pure-Python, readable, ~1000 lines total, no compiled
   dependencies.
4. **Reproducible.** Same inputs → same figures, offline.

---

## License & provenance

All equations are derived from public sources and all reference data are
nonproprietary, consistent with the NASA T-MATS release philosophy (Apache 2.0).
See [`docs/REFERENCES.md`](docs/REFERENCES.md) for full attribution.
