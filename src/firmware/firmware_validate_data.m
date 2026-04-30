function [out, prev] = firmware_validate_data(in, prev)
%FIRMWARE_VALIDATE_DATA  Apply HailMaryV1f range-clamp validation rules.
%
%   [OUT, PREV] = FIRMWARE_VALIDATE_DATA(IN, PREV) takes a struct or
%   table-row IN containing the firmware's sensor channels and returns
%   OUT with each out-of-range or NaN value replaced by the previous
%   valid sample held in PREV. PREV is updated and returned so the
%   function can be looped over a full flight CSV.
%
%   The clamps mirror the AVR validateData() function exactly:
%
%     UV          : sentinel -999 and NaN replaced
%     pressure    : 1000..120000 Pa
%     temperature : -100..+85 C
%     altitude    : -500..40000 m
%     gyro        : -2000..+2000 deg/s
%     accel       : -160..+160 m/s^2 (BNO055 +/-16 g)
%     mag         : -200..+200 uT  (signed - V1e bug fixed in V1f)
%
%   Use FIRMWARE_REPLAY_FILE to run the entire CSV through this
%   validator and produce the same "previous-value substitution" trace
%   that the AVR keeps in RAM.

if nargin < 2 || isempty(prev)
    prev = struct( ...
        'UV1A',0,'UV1B',0,'UV1C',0,'UV2A',0,'UV2B',0,'UV2C',0, ...
        'UV3A',0,'UV3B',0,'UV3C',0,'UV4A',0,'UV4B',0,'UV4C',0, ...
        'pressure_Pa',101325,'temp_C',15,'alt_m',0, ...
        'gyroX',0,'gyroY',0,'gyroZ',0, ...
        'accelX',0,'accelY',0,'accelZ',9.81, ...
        'magX',0,'magY',0,'magZ',0);
end

out = in;

uvFields = {'UV1A','UV1B','UV1C','UV2A','UV2B','UV2C', ...
            'UV3A','UV3B','UV3C','UV4A','UV4B','UV4C'};
for k = 1:numel(uvFields)
    f = uvFields{k};
    v = double(in.(f));
    if isnan(v) || v < -998
        out.(f) = prev.(f);
    else
        prev.(f) = v;
    end
end

p = double(in.pressure_Pa);
if p < 1000 || p > 120000 || isnan(p)
    out.pressure_Pa = prev.pressure_Pa;
else
    prev.pressure_Pa = p;
end

t = double(in.temp_C);
if isnan(t) || t < -100 || t > 85
    out.temp_C = prev.temp_C;
else
    prev.temp_C = t;
end

a = double(in.alt_m);
if isnan(a) || a < -500 || a > 40000
    out.alt_m = prev.alt_m;
else
    prev.alt_m = a;
end

gFields = {'gyroX','gyroY','gyroZ'};
for k = 1:3
    f = gFields{k};
    v = double(in.(f));
    if isnan(v) || v < -2000 || v > 2000
        out.(f) = prev.(f);
    else
        prev.(f) = v;
    end
end

aFields = {'accelX','accelY','accelZ'};
for k = 1:3
    f = aFields{k};
    v = double(in.(f));
    if isnan(v) || v < -160 || v > 160
        out.(f) = prev.(f);
    else
        prev.(f) = v;
    end
end

mFields = {'magX','magY','magZ'};
for k = 1:3
    f = mFields{k};
    v = double(in.(f));
    if isnan(v) || v < -200 || v > 200
        out.(f) = prev.(f);
    else
        prev.(f) = v;
    end
end
end
