# 00 — Systems-Engineering Overview

A NASA **ASCEND** / Arizona Near Space Research (**ANSR**) high-altitude balloon
flight is a complete aerospace systems-engineering exercise compressed into a
single afternoon and a ~$300 balloon. This toolkit decomposes that exercise into
the canonical subsystems and gives each a small, auditable physical model.

## The mission, end to end

```
   FILL ─▶ LAUNCH ─▶ ASCENT ─▶ BURST ─▶ DESCENT ─▶ LANDING ─▶ RECOVERY
   (gas)   (release)  ~5 m/s    ~33 km   parachute   ~5 m/s    (APRS)
     │         │         │         │         │          │          │
   lift_gas  balloon  balloon   balloon   descent    descent     comms
              flight   flight    flight    flight     flight     flight
                          │ thermal (whole flight)         │
                          └────────── comms (whole flight) ┘
```

## Subsystem ↔ model map

| Subsystem | Engineering question | Module | Doc |
|---|---|---|---|
| Environment | What are P, T, ρ, a vs altitude? | `atmosphere` | [01](01_ATMOSPHERE.md) |
| Lift | How much gas? What free lift? | `lift_gas` | [02](02_BALLOON_ASCENT.md) |
| Ascent | How fast, how high, when burst? | `balloon` | [02](02_BALLOON_ASCENT.md) |
| Recovery | How fast does it land? Is it safe? | `descent` | [03](03_DESCENT_RECOVERY.md) |
| Thermal | Will the electronics survive? | `thermal` | [04](04_THERMAL.md) |
| Comms | Can we hear/track it? Recover it? | `comms` | [05](05_COMMS_APRS.md) |
| Trajectory | Where does it land? | `flight` | [06](06_FLIGHT_PREDICTION.md) |
| Compliance | Is the flight legal? | — | [FAA](FAA_PART101.md) |

## The NASA SE "Vee", applied

Following the **NASA Systems Engineering Handbook (NASA/SP-2016-6105 Rev2)**:

- **Requirements (left of the Vee).** Mission ⇒ reach ≥ 30 km, recover payload
  intact, downlink live telemetry, land at < safe impact energy, comply with
  14 CFR Part 101. Each requirement maps to a model output above.
- **Design & analysis (bottom).** This toolkit *is* the analysis layer: size the
  balloon for a target burst altitude and ascent rate, size the parachute for a
  target landing velocity, budget the RF link, and predict the landing ellipse.
- **Verification (right of the Vee).** `tests/test_validation.py` verifies the
  models against published reference data (USSA-1976 tables, known flight
  ranges). On flight day, the ASCEND-S26 suite (`../matlab_ASCEND_S26/`)
  reconstructs the *actual* flight from recovered data and APRS — closing the
  loop between prediction and measurement.

## Margins philosophy

Each subsystem carries an explicit margin, in the spirit of NASA design
standards:

| Subsystem | Margin held | Default |
|---|---|---|
| Lift | free lift above neutral buoyancy | +1.2 kg |
| Recovery | landing velocity below hazard | < 6 m/s target |
| Thermal | interior within electronics range | −40 … +85 °C |
| Comms | link margin above closure | ≥ 10 dB |
| Trajectory | predicted vs no-fly / terrain | recovery-access check |

## How to use it on a real flight

1. **Pre-flight sizing** — run `examples/02` and `03` to choose balloon + chute
   for your payload mass and target altitude/landing speed.
2. **Go/no-go** — feed the morning's NOAA GFS winds into `examples/06` to
   predict the landing point and confirm it is recoverable and clear of
   restricted airspace.
3. **Link check** — run `examples/05` to confirm your tracker closes the link to
   the nearest APRS digipeater across the whole flight.
4. **Thermal check** — run `examples/04` to confirm your heater/insulation
   budget keeps the electronics alive at the cold point (~ tropopause and float).
5. **Post-flight** — reconstruct the real flight with the ASCEND-S26 MATLAB
   suite and compare to the prediction.
