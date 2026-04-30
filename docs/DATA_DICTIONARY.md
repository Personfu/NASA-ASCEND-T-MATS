# ASCEND Spring 2026 - Data Dictionary

> Authored by *Personfu*. Every column in every ingested timetable.

## D.trajectory (APRS-derived, 171 fixes)
| Field | Unit | Notes |
|---|---|---|
| t (RowTime) | datetime UTC | First fix at 2026-03-28 16:38:54 |
| t_s | s | Seconds since launch |
| lat | deg N | WGS-84 |
| lon | deg E (negative W) | WGS-84 |
| alt_m | m MSL | GPS WGS-84 |
| alt_ft | ft MSL | Convenience |
| gs_mph | mph | APRS-reported ground speed |
| course_deg | deg | APRS-reported course over ground |
| vz_fps | fps | derived dh/dt |
| vz_ms  | m/s | derived |
| vz_mph | mph | derived |
| az_fps2 | ft/s^2 | derived dvz/dt |
| az_g | g | derived |
| phase | string | "launch","ascent","apex","descent","landed" |

UserData: `apex_idx` (row of apex altitude).

## D.wind (windspeed_vs_altitude_calculation)
| Field | Unit | Notes |
|---|---|---|
| t | datetime UTC | from APRS |
| alt_m, alt_ft | m / ft | MSL |
| dist_km | km | Vincenty inverse from launch |
| vlat_mph, vlat_ms | mph, m/s | lateral wind speed (segment) |
| vz_mph, vz_ms     | mph, m/s | vertical speed |
| vnet_mph, vnet_ms | mph, m/s | net speed |

## D.geiger (GMC-320+, 3792 samples)
| Field | Unit | Notes |
|---|---|---|
| t (UTC) | datetime | converted from local Phoenix MST |
| dose_uSvph | uSv/h | from CPM via tube factor |
| cpm | counts/min | raw |
| sample_type | string | "EveryS"/"EveryM" |

## D.multi (PMS5003 + SCD30, 4171 samples)
| Field | Unit |
|---|---|
| t (UTC) | datetime (local->UTC) |
| pm10, pm25, pm100 | ug/m^3 |
| pm0_3, pm0_5, pm1, pm2_5, pm5, pm10_count | particles/0.1 L |
| co2_ppm | ppm |
| temp_C | C |
| rh_pct | % |
| elapsed_s | s |
| alt_m | m (from BMP/GPS sync, if present) |

## D.arduino (UV + BMP390 + ICM-20948 + LIS3MDL, 10010 samples)
| Field | Unit |
|---|---|
| t | datetime |
| uva1..uva4, uvb1..uvb4, uvc1..uvc4 | mW/cm^2 |
| UVA_mWcm2, UVB_mWcm2, UVC_mWcm2 | mW/cm^2 (mean of triads) |
| press_pa | Pa |
| temp_c | C (BMP390) |
| alt_baro_m | m (BMP390) |
| acc_x, acc_y, acc_z | m/s^2 |
| accel_total_g | g |
| gyro_x, gyro_y, gyro_z | dps |
| mag_x, mag_y, mag_z | uT |

After fusion (`sensor_fusion_attitude`): `q0,q1,q2,q3,roll_deg,pitch_deg,yaw_deg`.

## sim.ascent3d
ENU position (`x_E,x_N,x_U`), velocity (`v_E,v_N,v_U`), `speed`, `lat`, `lon`,
`T_K`, `P_Pa`, `rho`, `Vb_m3`, `Db_m`, `Mach`, `Re`.

## sim.descent3d
`x_E,x_N,x_U,v_E,v_N,v_U,speed,CdA_m2,F_shock_N,Mach,rho`.
UserData: `peak_shock_N`, `peak_g`, `impact_v_ms`, `drift_km`.

## link
All trajectory fields plus
`d_km, fspl_dB, atm_dB, prx_dBm, snr_dB, elev_deg, los_horizon_km, link_margin_dB`.

## MC (monte carlo)
`land_km(N,2), mean_km, cov_km2, cep50_km, cep95_km, ellipse_axes,
ellipse_ang, apex_m, impact_ms, N`.
