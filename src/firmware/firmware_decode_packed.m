function out = firmware_decode_packed(field, val)
%FIRMWARE_DECODE_PACKED  Unpack HailMaryV1f packed-byte CSV columns.
%
%   OUT = FIRMWARE_DECODE_PACKED('bno_cal', VAL) returns a struct with
%       .sys .gyro .accel .mag (each 0..3) decoded from the BNO055
%       calibration byte.
%
%   OUT = FIRMWARE_DECODE_PACKED('health', VAL) returns a struct with
%       .UV1 .UV2 .UV3 .UV4 .BMP .BNO .SD .GPS (each logical) decoded
%       from the sensor-health bitmask.
%
%   OUT = FIRMWARE_DECODE_PACKED('phase', VAL) returns a categorical
%       label among {ground, ascent, float, descent, landed}.
%
%   VAL may be a scalar, vector, matrix, or column extracted from a
%   timetable - the decoder is fully vectorised. The encoding mirrors
%   the firmware exactly:
%
%     bno_cal = (sys<<6) | (gyro<<4) | (accel<<2) | mag
%     health  = b7=UV1 b6=UV2 b5=UV3 b4=UV4 b3=BMP b2=BNO b1=SD b0=GPS
%     phase   = 0=ground 1=ascent 2=float 3=descent 4=landed

field = lower(string(field));
b = uint8(val);

switch field
    case "bno_cal"
        out = struct( ...
            'sys',   double(bitshift(b, -6)), ...
            'gyro',  double(bitand(bitshift(b, -4), uint8(3))), ...
            'accel', double(bitand(bitshift(b, -2), uint8(3))), ...
            'mag',   double(bitand(b, uint8(3))));

    case "health"
        out = struct( ...
            'UV1', logical(bitand(b, uint8(0x80))), ...
            'UV2', logical(bitand(b, uint8(0x40))), ...
            'UV3', logical(bitand(b, uint8(0x20))), ...
            'UV4', logical(bitand(b, uint8(0x10))), ...
            'BMP', logical(bitand(b, uint8(0x08))), ...
            'BNO', logical(bitand(b, uint8(0x04))), ...
            'SD',  logical(bitand(b, uint8(0x02))), ...
            'GPS', logical(bitand(b, uint8(0x01))));

    case "phase"
        names = ["ground","ascent","float","descent","landed"];
        v = double(val);
        v(isnan(v)) = 0;
        v = max(0, min(4, round(v)));
        out = categorical(names(v + 1)', names, 'Ordinal', true);

    otherwise
        error('firmware_decode_packed:UnknownField', ...
            'Unknown packed field "%s". Use bno_cal, health, or phase.', field);
end
end
