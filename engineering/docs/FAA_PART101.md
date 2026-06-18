# Regulatory Compliance — 14 CFR Part 101 (Unmanned Free Balloons)

> **Disclaimer.** This is an engineering summary for planning, not legal advice.
> Always consult the current text of **14 CFR Part 101** and FAA **AC 101-1**,
> and coordinate with your local FSDO and (for NASA-ASCEND) your program / range
> safety office before any launch.

U.S. high-altitude balloon flights are governed by **14 CFR Part 101, Subpart D
— Unmanned Free Balloons**. The toolkit's recovery and trajectory models exist
in part to demonstrate compliance with the **exempt (light)** category so a
student flight can operate without special authorization.

## When Part 101 Subpart D applies

The operating rules apply to an unmanned free balloon **unless** it is small
enough to be exempt under **§ 101.1(a)(4)**. The exemptions include a balloon
carrying a payload package that:

- weighs **< 4 lb (1.8 kg)** with a payload/area density **≤ 3 oz/in²**, **or**
- has a payload **6–12 lb (2.7–5.4 kg)** with package area density ≤ 3 oz/in²
  *(and other combinations defined in the rule).*

The **area density** test (package weight ÷ smallest surface area) limits impact
severity. Keeping each payload package light and not too dense is the simplest
path to the exempt category. Multiple light packages are generally preferable to
one heavy, dense one.

## Key engineering-relevant requirements (if not exempt)

| Rule | Requirement | Toolkit support |
|---|---|---|
| § 101.33 reflectivity | radar-reflective / visible as required | (hardware: radar reflector) |
| § 101.35 lighting | position lights for night ops | (hardware) |
| § 101.37 notice | file launch notice with ATC | trajectory product ([06](06_FLIGHT_PREDICTION.md)) |
| § 101.39 position reports | report position/altitude | APRS telemetry ([05](05_COMMS_APRS.md)) |
| Rapid descent / cut-down | terminate flight safely | descent model ([03](03_DESCENT_RECOVERY.md)) |

## How the models support compliance

- **Impact energy / landing velocity** ([03](03_DESCENT_RECOVERY.md)).
  The descent model computes landing kinetic energy (e.g., **6.5 J** for a
  1.2 kg payload under a 60-inch chute) — evidence the package lands gently.
  Size the parachute so the landing energy stays low and the payload qualifies
  on the area-density basis.
- **Trajectory / airspace deconfliction** ([06](06_FLIGHT_PREDICTION.md)).
  The flight predictor produces the ground track and landing point used to file
  notice with ATC and to confirm the path and landing avoid restricted /
  special-use airspace.
- **Position reporting** ([05](05_COMMS_APRS.md)).
  The APRS link budget confirms continuous position/altitude downlink across the
  whole flight, satisfying position-report expectations and enabling recovery.

## Good-practice checklist (engineering)

- [ ] Keep each payload package within the exempt weight / area-density limits.
- [ ] Parachute sized for low landing velocity & impact energy ([03](03_DESCENT_RECOVERY.md)).
- [ ] Predicted landing clear of airports, controlled/restricted airspace, water,
      and populated areas ([06](06_FLIGHT_PREDICTION.md)).
- [ ] Independent / redundant tracking (APRS + secondary tracker).
- [ ] Cut-down or burst-only flight plan with a bounded float scenario.
- [ ] NOTAM / ATC notice filed where required; program safety review complete.
- [ ] Recovery crew briefed on predicted landing and ~150 min flight time.

## References

- **14 CFR Part 101**, Subpart D — Unmanned Free Balloons (current eCFR text).
- **FAA Advisory Circular AC 101-1**, *Unmanned Free Balloon Operations*.
- See [`REFERENCES.md`](REFERENCES.md) §8 for full citations.
