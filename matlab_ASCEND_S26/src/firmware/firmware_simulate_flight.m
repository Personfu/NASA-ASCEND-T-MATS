function T = firmware_simulate_flight(profile, opts)
%FIRMWARE_SIMULATE_FLIGHT  Emulate a HailMaryV1f flight log.
%
%   T = FIRMWARE_SIMULATE_FLIGHT(PROFILE) generates a synthetic
%   `asusux.csv`-equivalent timetable using the firmware's own logic:
%
%       * 500 ms sample period (writeInterval)
%       * range-clamp validation with previous-value substitution
%       * altitude-driven flight-phase state machine
%       * impact detector armed during DESCENT
%       * vertical velocity, accel magnitude, free-RAM bookkeeping
%       * packed bno_cal and health bytes
%
%   PROFILE is a struct with optional fields:
%       .duration_s   total flight time         (default 7200)
%       .ascent_rate  m/s                       (default 4.5)
%       .descent_rate m/s after burst           (default 9.5)
%       .peak_alt_m   burst altitude (m)        (default 25145)
%       .ground_alt_m launch altitude (m)       (default 480)
%       .impact_t     time of ground strike (s) (default duration-30)
%
%   T = FIRMWARE_SIMULATE_FLIGHT(PROFILE, OPTS) accepts:
%       .seed         RNG seed for repeatable runs
%       .csvOut       path to write the simulated CSV (optional)
%
%   The output is the same timetable shape produced by
%   FIRMWARE_DECODE_CSV, so every downstream MATLAB tool (decoder,
%   health summary, dashboards) works identically against simulated
%   and recovered data.

if nargin < 1 || isempty(profile), profile = struct(); end
if nargin < 2 || isempty(opts),    opts    = struct(); end

prof = struct( ...
    'duration_s',  7200, ...
    'ascent_rate',  4.5, ...
    'descent_rate', 9.5, ...
    'peak_alt_m', 25145, ...
    'ground_alt_m', 480, ...
    'impact_t',   NaN);
fn = fieldnames(profile);
for k = 1:numel(fn), prof.(fn{k}) = profile.(fn{k}); end
if isnan(prof.impact_t), prof.impact_t = prof.duration_s - 30; end

if isfield(opts, 'seed') && ~isempty(opts.seed), rng(opts.seed); else, rng(0); end

dt = 0.5;
t  = (0:dt:prof.duration_s).';
N  = numel(t);

% --- Altitude profile: ascent ramp -> burst peak -> descent ramp -> ground
ascent_t  = (prof.peak_alt_m - prof.ground_alt_m) / prof.ascent_rate;
descent_t = (prof.peak_alt_m - prof.ground_alt_m) / prof.descent_rate;
alt = zeros(N,1);
for i = 1:N
    if t(i) < ascent_t
        alt(i) = prof.ground_alt_m + prof.ascent_rate * t(i);
    elseif t(i) < ascent_t + descent_t
        alt(i) = prof.peak_alt_m - prof.descent_rate * (t(i) - ascent_t);
    else
        alt(i) = prof.ground_alt_m;
    end
end
alt = alt + 0.6*randn(N,1);  % BMP noise

% --- Pressure/temp from US-1976 lite
[pressurePa, temp_C] = local_atmos(alt);
pressurePa = pressurePa + 25*randn(N,1);
temp_C     = temp_C   + 0.4*randn(N,1);

% --- IMU: gravity vector + tumble + burst spike + impact spike
ax = 0.4*randn(N,1);
ay = 0.4*randn(N,1);
az = 9.81 + 0.4*randn(N,1);

burstIdx = round(ascent_t / dt) + 1;
burstWin = burstIdx + (-4:8);
burstWin = burstWin(burstWin>=1 & burstWin<=N);
ax(burstWin) = ax(burstWin) + 14*randn(numel(burstWin),1);
ay(burstWin) = ay(burstWin) + 12*randn(numel(burstWin),1);
az(burstWin) = az(burstWin) + 25*randn(numel(burstWin),1);

descIdx = burstIdx + (1:round(descent_t/dt));
descIdx = descIdx(descIdx<=N);
az(descIdx) = az(descIdx) + 4.0;  % chute-loaded ~9 g during canopy descent

impactIdx = round(prof.impact_t / dt) + 1;
if impactIdx >= 1 && impactIdx <= N
    iw = impactIdx + (0:3);
    iw = iw(iw<=N);
    ax(iw) = ax(iw) + 90;
    ay(iw) = ay(iw) - 60;
    az(iw) = az(iw) + 110;
end

gx = 30*randn(N,1);  gy = 30*randn(N,1);  gz = 30*randn(N,1);
mx = -22 + 5*randn(N,1);  my = 14 + 5*randn(N,1);  mz = -39 + 5*randn(N,1);

% --- UV: zero on ground, ramps with altitude (Beer-Lambert-ish)
uvScale = max(0, alt - prof.ground_alt_m) / max(1, prof.peak_alt_m - prof.ground_alt_m);
UV1A = 80 + 220*uvScale + 4*randn(N,1);
UV1B = 30 +  90*uvScale + 2*randn(N,1);
UV1C =  2 +  18*uvScale + 1*randn(N,1);
UV2A = UV1A + 3*randn(N,1);  UV2B = UV1B + 2*randn(N,1);  UV2C = UV1C + 1*randn(N,1);
UV3A = UV1A + 3*randn(N,1);  UV3B = UV1B + 2*randn(N,1);  UV3C = UV1C + 1*randn(N,1);
UV4A = UV1A + 3*randn(N,1);  UV4B = UV1B + 2*randn(N,1);  UV4C = UV1C + 1*randn(N,1);

% --- Validate every row through the firmware twin
prev = [];
fields = {'UV1A','UV1B','UV1C','UV2A','UV2B','UV2C','UV3A','UV3B','UV3C', ...
          'UV4A','UV4B','UV4C','pressure_Pa','temp_C','alt_m', ...
          'gyroX','gyroY','gyroZ','accelX','accelY','accelZ','magX','magY','magZ'};
M = numel(fields);
data = struct();
for k = 1:M, data.(fields{k}) = zeros(N,1); end

for i = 1:N
    in = struct(...
        'UV1A',UV1A(i),'UV1B',UV1B(i),'UV1C',UV1C(i), ...
        'UV2A',UV2A(i),'UV2B',UV2B(i),'UV2C',UV2C(i), ...
        'UV3A',UV3A(i),'UV3B',UV3B(i),'UV3C',UV3C(i), ...
        'UV4A',UV4A(i),'UV4B',UV4B(i),'UV4C',UV4C(i), ...
        'pressure_Pa',pressurePa(i),'temp_C',temp_C(i),'alt_m',alt(i), ...
        'gyroX',gx(i),'gyroY',gy(i),'gyroZ',gz(i), ...
        'accelX',ax(i),'accelY',ay(i),'accelZ',az(i), ...
        'magX',mx(i),'magY',my(i),'magZ',mz(i));
    [out, prev] = firmware_validate_data(in, prev);
    for k = 1:M, data.(fields{k})(i) = out.(fields{k}); end
end

% --- Phase state machine
phase = firmware_flight_phase(data.alt_m, true(N,1));

% --- Derived columns
vert = [0; diff(data.alt_m) / dt];
mag  = sqrt(data.accelX.^2 + data.accelY.^2 + data.accelZ.^2);
freeRam = round(linspace(5800, 4500, N).' + 30*randn(N,1));

% --- Stale counters: simulate a few BMP misses near burst
staleBmp = zeros(N,1); staleBno = zeros(N,1);
miss = randi(N, 1, round(N*0.01));
staleBmp(miss) = 1;

% --- BNO calibration: typical post-launch convergence sys=3 g=3 a=3 m=2
calByte = uint8(bitor(bitor(bitor(bitshift(uint8(3),6), bitshift(uint8(3),4)), ...
                            bitshift(uint8(3),2)), uint8(2)));

% --- Health bitmask: all up, GPS only after t>120s (fix acquisition)
health = zeros(N,1,'uint8');
for i = 1:N
    h = uint8(bin2dec('11111110'));  % all up except GPS
    if t(i) > 120, h = bitor(h, uint8(0x01)); end
    health(i) = h;
end

% --- GPS columns: sats and HDOP
sats = zeros(N,1); hdop = 9999*ones(N,1); gpsAlt = zeros(N,1);
sats(t>120) = 9 + round(2*randn(sum(t>120),1));
hdop(t>120) = round(120 + 30*randn(sum(t>120),1));
gpsAlt = data.alt_m + 5*randn(N,1);

% Synthesize a UTC time string for each row
utc = strings(N,1);
launchUTC = datetime(2026,3,28,16,30,0,'TimeZone','UTC');
for i = 1:N
    if t(i) > 120
        ti = launchUTC + seconds(t(i));
        utc(i) = string(datestr(ti,'HH:MM:SS'));
    else
        utc(i) = "";
    end
end

% Fixed launch coordinates for sim (Casa Grande, AZ launch site)
lat = 32.87533 + 0.0008*sin(t/600);
lng = -112.0495 + 0.0010*cos(t/450);

R = table( ...
    round(t*1000), data.UV1A, data.UV1B, data.UV1C, ...
    data.UV2A, data.UV2B, data.UV2C, ...
    data.UV3A, data.UV3B, data.UV3C, ...
    data.UV4A, data.UV4B, data.UV4C, ...
    data.pressure_Pa, data.temp_C, data.alt_m, ...
    data.gyroX, data.gyroY, data.gyroZ, ...
    data.accelX, data.accelY, data.accelZ, ...
    data.magX, data.magY, data.magZ, ...
    utc, lat, lng, sats, hdop, gpsAlt, ...
    staleBmp, staleBno, repmat(double(calByte),N,1), double(health), double(phase), ...
    vert, mag, freeRam, ...
    'VariableNames', {'elapsed_ms', ...
        'UV1A','UV1B','UV1C','UV2A','UV2B','UV2C', ...
        'UV3A','UV3B','UV3C','UV4A','UV4B','UV4C', ...
        'pressure_Pa','temp_C','alt_m', ...
        'gyroX','gyroY','gyroZ','accelX','accelY','accelZ', ...
        'magX','magY','magZ','time_utc','lat','lng', ...
        'gps_sats','gps_hdop','gps_alt_m', ...
        'stale_bmp','stale_bno','bno_cal','health','phase', ...
        'vert_vel_mps','accel_mag_mps2','free_ram'});

% Decode packed columns (so the simulator output matches the decoder)
calB = uint8(R.bno_cal);
R.cal_sys   = double(bitshift(calB,-6));
R.cal_gyro  = double(bitand(bitshift(calB,-4),3));
R.cal_accel = double(bitand(bitshift(calB,-2),3));
R.cal_mag   = double(bitand(calB,3));
hB = uint8(R.health);
R.h_UV1 = logical(bitand(hB, uint8(0x80)));
R.h_UV2 = logical(bitand(hB, uint8(0x40)));
R.h_UV3 = logical(bitand(hB, uint8(0x20)));
R.h_UV4 = logical(bitand(hB, uint8(0x10)));
R.h_BMP = logical(bitand(hB, uint8(0x08)));
R.h_BNO = logical(bitand(hB, uint8(0x04)));
R.h_SD  = logical(bitand(hB, uint8(0x02)));
R.h_GPS = logical(bitand(hB, uint8(0x01)));
phaseNames = ["ground","ascent","float","descent","landed"];
R.phase_label = categorical(phaseNames(R.phase + 1)', phaseNames, 'Ordinal', true);

T = table2timetable(R, 'RowTimes', seconds(t));
T.Properties.Description = 'HailMaryV1f firmware-in-the-loop simulated flight';

if isfield(opts,'csvOut') && ~isempty(opts.csvOut)
    csvT = R; csvT.cal_sys = []; csvT.cal_gyro = []; csvT.cal_accel = [];
    csvT.cal_mag = []; csvT.h_UV1 = []; csvT.h_UV2 = []; csvT.h_UV3 = [];
    csvT.h_UV4 = []; csvT.h_BMP = []; csvT.h_BNO = []; csvT.h_SD = [];
    csvT.h_GPS = []; csvT.phase_label = [];
    writetable(csvT, opts.csvOut);
end
end

function [P, Tk] = local_atmos(h)
% US-1976 troposphere/lower-stratosphere lite
T0 = 288.15; P0 = 101325; L = 0.0065; R = 287.05; g = 9.80665;
P = zeros(size(h)); Tk = zeros(size(h));
for i = 1:numel(h)
    if h(i) < 11000
        Tk(i) = T0 - L*h(i);
        P(i)  = P0 * (Tk(i)/T0)^(g/(R*L));
    else
        T11 = T0 - L*11000;
        P11 = P0 * (T11/T0)^(g/(R*L));
        Tk(i) = T11;
        P(i)  = P11 * exp(-g*(h(i)-11000)/(R*T11));
    end
end
Tk = Tk - 273.15;
end
