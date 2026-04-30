# ASCEND Spring 2026 - Operations & Mission Timeline

> Authored by *Personfu* for Phoenix College NASA ASCEND.

## 1. Pre-launch L-7 days
- File NOTAM with FSS (Part 101 Light, no NOTAM technically required, courtesy filing)
- Verify APRS test transmission, receive on N-AZ digipeaters (W7DG-1, W7ARA-1)
- Charge no batteries (L91 are primaries) - install fresh cells day-of
- Run `payload_systems.m` to confirm mass/CG/areal density compliance

## 2. L-1 day
- Run `weather_predict()` (NOAA RAW MD reading) and ground-track forecast
- Brief launch crew on recovery roles
- Pre-bag balloon in Mylar to prevent UV damage and oils

## 3. L-0 (launch morning)
| T-time | Event |
|---|---|
| T-180 min | Arrive at site (32.87533 N, 112.0495 W) |
| T-150 min | Final radio check; APRS beacon on UTC (test) |
| T-90  min | Begin balloon fill (Helium 99.99%, ~4.2 m^3 at launch alt) |
| T-30  min | Multisensor + Arduino + Geiger power-on (logs start) |
| T-15  min | Tracker active beacon every 60 s |
| T-5   min | Final FAA notification call |
| T-0       | Release |
| T+1 h     | Expected apex (~25 km) |
| T+2 h     | Expected impact (per dispersion median) |

## 4. In-flight monitoring
- aprs.fi tracking on KA7NSR-15
- Backup SDR at base station (RTL-SDR + direwolf)
- Predict update every 15 min using `simulate_3d_descent` from current alt+vel

## 5. Recovery
- Drive to predicted landing zone
- Use 144.39 MHz handheld for last 5 km
- Visual-spot orange box (color FAFAFA per `payload_systems`)
- Power off all loggers, secure SD/EEPROM cards before transport

## 6. Post-flight
- Run `ASCEND_S26_run` to ingest, simulate, validate, render report
- Archive `data/raw/` to OneDrive
- File post-mission report with NASA ASCEND program

## 7. Roles
| Role | Person | Backup |
|---|---|---|
| FAA / Launch Director | *(TBD)* | *(TBD)* |
| Filling Lead | *(TBD)* | *(TBD)* |
| Ground Comm | *(TBD)* | *(TBD)* |
| Recovery Lead | *(TBD)* | *(TBD)* |
| Data / Sim Lead | Personfu | *(TBD)* |
