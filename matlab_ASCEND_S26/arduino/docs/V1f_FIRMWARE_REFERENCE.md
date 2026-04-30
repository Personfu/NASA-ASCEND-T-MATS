# HailMaryV1f Firmware Reference

This document is the authoritative companion to
`arduino/HailMaryV1f/HailMaryV1f.ino`, the firmware that flew on the Phoenix
College NASA ASCEND Spring 2026 carbon-fiber bodied 3 lb payload "Phoenix-1".

The MATLAB suite under `src/firmware/` mirrors the firmware's CSV schema,
packed-byte encodings, validation logic, flight-phase state machine, impact
detector, and EEPROM backup so any real or simulated `asusux.csv` can be
decoded byte-for-byte the same way the AVR does.

## Hardware Stack

| Subsystem | Part            | Bus / Pin                                     |
|-----------|-----------------|-----------------------------------------------|
| MCU       | Arduino Mega 2560 | -                                           |
| Pressure  | BMP388 / BMP390 | Software SPI (CS=10, SCK=13, MISO=12, MOSI=11) |
| IMU       | BNO055 (NDOF)   | I²C @ 0x28                                    |
| UV ×4     | SparkFun AS7331 | I²C @ 0x74, 0x75, 0x76, 0x77                  |
| GPS       | VK2828U7G5LF (u-blox G7020) | UART Serial1 @ 9600 baud (pins 18/19) |
| Storage   | SD card         | SPI CS=53, file `asusux.csv`                  |
| Backup    | AVR EEPROM      | 4 KB internal, addresses 0–11 for GPS lat/lng/alt |

## Timing Budget

| Activity            | Period   | Notes                                            |
|---------------------|----------|--------------------------------------------------|
| `loop()` / WDT pet  | continuous | `wdt_enable(WDTO_8S)` resets MCU on bus hangs |
| `logData()`         | 500 ms   | `writeInterval`                                  |
| `flushBuffer()`     | 5 s      | `bufferFlushInterval`                            |
| UV recovery sweep   | 5 s      | `recoveryInterval`                               |
| SD recovery retry   | 5 s      | `sdRecoveryInterval`                             |
| BMP cold recovery   | 30 s     | `BMP_COLD_RECOVERY_MS`                           |
| EEPROM GPS backup   | 30 s     | `eepromWriteInterval` (≈ 34 days @ 100 k cycles) |

## CSV Schema (37 columns)

```
1  elapsed(ms)
2  UV1A(uW/cm2)   3  UV1B   4  UV1C
5  UV2A           6  UV2B   7  UV2C
8  UV3A           9  UV3B  10  UV3C
11 UV4A          12 UV4B   13 UV4C
14 pressure(Pa)
15 temp(C)
16 alt(m)
17 gyroX(deg/s) 18 gyroY  19 gyroZ
20 accelX(m/s2) 21 accelY 22 accelZ
23 magX(uT)     24 magY   25 magZ
26 time_utc        (HH:MM:SS, blank if no fix)
27 lat             (signed decimal degrees, 6 dp from int32×1e6)
28 lng             (signed decimal degrees, 6 dp from int32×1e6)
29 gps_sats        (uint8)
30 gps_hdop        (HDOP, decimal, x100 stored, 9999=unknown)
31 gps_alt(m)      (decimal m, from int32 cm)
32 stale_bmp       (consecutive BMP stale reads)
33 stale_bno       (consecutive BNO stale reads)
34 bno_cal         (packed: sys|gyro|accel|mag, each 2 bits)
35 health          (bitmask: UV1|UV2|UV3|UV4|BMP|BNO|SD|GPS)
36 phase           (0=ground 1=ascent 2=float 3=descent 4=landed)
37 vert_vel(m/s)
38 accel_mag(m/s2)
39 free_ram(bytes)
```

> Note: column 1 is the `elapsed(ms)` AVR `millis()` stamp. Columns 26–31 are
> the GPS block. Columns 32–36 are research metadata. Columns 37–39 are the
> derived per-row engineering quantities.

## Packed-Byte Decoding

### `bno_cal` (uint8 0–255)

```
sys   = bitshift(val, -6)            % bits 7..6
gyro  = bitand(bitshift(val,-4), 3)  % bits 5..4
accel = bitand(bitshift(val,-2), 3)  % bits 3..2
mag   = bitand(val, 3)               % bits 1..0
```

Each sub-field is 0..3 (BNO055 native calibration scale).

### `health` (uint8 0–255)

| Bit | Sensor              | Mask  |
|-----|---------------------|-------|
| 7   | UV1 (AS7331 0x74)   | 0x80  |
| 6   | UV2 (AS7331 0x75)   | 0x40  |
| 5   | UV3 (AS7331 0x76)   | 0x20  |
| 4   | UV4 (AS7331 0x77)   | 0x10  |
| 3   | BMP3xx (and not cold-dead) | 0x08 |
| 2   | BNO055              | 0x04  |
| 1   | SD card             | 0x02  |
| 0   | GPS valid location  | 0x01  |

A row of `health = 0xFE` therefore means every sensor up except the GPS lock.

### `phase` (uint8 0–4)

| Code | Phase    | Trigger                                                  |
|------|----------|----------------------------------------------------------|
| 0    | GROUND   | Initial state                                            |
| 1    | ASCENT   | `alt - launch > 100 m`                                   |
| 2    | FLOAT    | 5 consecutive samples with `|d_alt| < 2 m`               |
| 3    | DESCENT  | `peak - alt > 50 m`                                      |
| 4    | LANDED   | `alt - launch < 200 m AND |d_alt| < 1 m` OR impact >15 g |

## Validation Limits

The firmware substitutes the previous valid value whenever a reading is NaN
or out of range. The MATLAB decoder applies the same rules in
`firmware_validate_data.m`:

| Channel    | Range used by firmware         |
|------------|--------------------------------|
| UV         | sentinel `-999` and NaN replaced |
| pressure   | 1 000–120 000 Pa               |
| temperature| -100 to +85 °C                  |
| altitude   | -500 to 40 000 m               |
| gyro       | -2000 to +2000 °/s             |
| accel      | -160 to +160 m/s² (BNO055 ±16 g) |
| mag        | -200 to +200 µT (signed)       |

## Impact Detection

Armed only during DESCENT/LANDED phases. Threshold:

```
|a| > IMPACT_THRESHOLD_MS2 = 147 m/s² (≈ 15 g)
```

When tripped: `flightPhase = LANDED`, `flushBuffer()`, and a final
`SD.open + flush + close` cycle commit the FAT table.

## EEPROM Layout

```
0  ..  3   int32  latE6  (latitude  × 1 000 000)
4  ..  7   int32  lngE6  (longitude × 1 000 000)
8  .. 11   int32  altCm  (altitude in cm)
```

Blank EEPROM (all `0xFF`, i.e. -1) is treated as "no previous position".

## UBX-CFG-NAV5 Airborne <1 g>

The firmware ships a 44-byte UBX-CFG-NAV5 packet over Serial1 at boot:

```
B5 62 06 24 24 00 FF FF 06 03 00 00 00 00 10 27 00 00
05 00 FA 00 FA 00 64 00 2C 01 00 00 00 00 00 00 00 00
00 00 00 00 00 00 ckA ckB
```

Setting `dynModel = 6` (Airborne <1 g>) raises the COCOM altitude ceiling from
~12 km to 50 km and is the reason the Spring 2026 GPS column kept reporting
fixes through 25 145 m AMSL. The Fletcher-8 checksum is computed over bytes
2..41 inclusive.
