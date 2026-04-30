function T = firmware_decode_csv(csvPath)
%FIRMWARE_DECODE_CSV  Read an `asusux.csv` file written by HailMaryV1f.
%
%   T = FIRMWARE_DECODE_CSV(CSVPATH) returns a MATLAB timetable with one
%   row per logged sample. The 37-column V1f schema is decoded exactly as
%   the firmware writes it, including:
%
%     * scaled-integer GPS lat/lng (6 dp from int32×1e6)
%     * packed BNO055 calibration byte (`bno_cal` -> sys/gyro/accel/mag)
%     * sensor-health bitmask (`health` -> UV1..GPS booleans)
%     * flight phase (0..4 -> categorical)
%     * staleness counters and free-RAM trace
%
%   The output table also exposes derived columns (vertVelocity, accelMag)
%   so any downstream MATLAB simulation, plot, or KPI reads identical
%   numbers to the AVR.
%
%   Phoenix College NASA ASCEND Spring 2026 - HailMaryV1f.

if nargin < 1 || isempty(csvPath)
    error('firmware_decode_csv:NoPath', 'Provide a path to asusux.csv.');
end
if ~isfile(csvPath)
    error('firmware_decode_csv:NotFound', 'File not found: %s', csvPath);
end

opts = detectImportOptions(csvPath, 'NumHeaderLines', 1, ...
                          'TextType', 'string', ...
                          'EmptyLineRule', 'skip');
opts.VariableNames = { ...
    'elapsed_ms', ...
    'UV1A','UV1B','UV1C', ...
    'UV2A','UV2B','UV2C', ...
    'UV3A','UV3B','UV3C', ...
    'UV4A','UV4B','UV4C', ...
    'pressure_Pa','temp_C','alt_m', ...
    'gyroX','gyroY','gyroZ', ...
    'accelX','accelY','accelZ', ...
    'magX','magY','magZ', ...
    'time_utc','lat','lng', ...
    'gps_sats','gps_hdop','gps_alt_m', ...
    'stale_bmp','stale_bno','bno_cal','health','phase', ...
    'vert_vel_mps','accel_mag_mps2','free_ram'};

% Force string type for time_utc; everything else numeric.
strCols = {'time_utc'};
numCols = setdiff(opts.VariableNames, strCols);
opts = setvartype(opts, strCols, 'string');
opts = setvartype(opts, numCols, 'double');

R = readtable(csvPath, opts);

% Decode packed BNO055 calibration byte -> 4 columns
calByte = uint8(R.bno_cal);
R.cal_sys   = double(bitshift(calByte, -6));
R.cal_gyro  = double(bitand(bitshift(calByte, -4), 3));
R.cal_accel = double(bitand(bitshift(calByte, -2), 3));
R.cal_mag   = double(bitand(calByte, 3));

% Decode sensor-health bitmask -> 8 booleans
healthByte = uint8(R.health);
R.h_UV1 = logical(bitand(healthByte, 0x80));
R.h_UV2 = logical(bitand(healthByte, 0x40));
R.h_UV3 = logical(bitand(healthByte, 0x20));
R.h_UV4 = logical(bitand(healthByte, 0x10));
R.h_BMP = logical(bitand(healthByte, 0x08));
R.h_BNO = logical(bitand(healthByte, 0x04));
R.h_SD  = logical(bitand(healthByte, 0x02));
R.h_GPS = logical(bitand(healthByte, 0x01));

% Phase labels
phaseNames = ["ground","ascent","float","descent","landed"];
ph = R.phase;
ph(isnan(ph)) = 0;
ph = max(0, min(4, round(ph)));
R.phase_label = categorical(phaseNames(ph + 1)', phaseNames, 'Ordinal', true);

% Convert to timetable on elapsed seconds
elapsed_s = R.elapsed_ms / 1000;
t = seconds(elapsed_s);
T = table2timetable(R, 'RowTimes', t);
T.Properties.Description = 'HailMaryV1f decoded telemetry (Spring 2026)';
T.Properties.UserData = struct( ...
    'firmware', 'HailMaryV1f', ...
    'csvSource', csvPath, ...
    'rowCount', height(T), ...
    'decodedAt', datetime('now'));
end
