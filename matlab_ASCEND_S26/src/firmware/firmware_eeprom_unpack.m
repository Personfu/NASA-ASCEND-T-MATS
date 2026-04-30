function [latDeg, lngDeg, altMeters] = firmware_eeprom_unpack(bytes)
%FIRMWARE_EEPROM_UNPACK  Decode the 12-byte EEPROM block read by V1f.
%
%   [LAT, LNG, ALT] = FIRMWARE_EEPROM_UNPACK(BYTES) decodes the 12-byte
%   uint8 buffer that the firmware reads on boot via EEPROM.get():
%
%       0..3  : int32 latE6 -> degrees
%       4..7  : int32 lngE6 -> degrees
%       8..11 : int32 altCm -> meters
%
%   A blank EEPROM (all 0xFF) decodes to lat=lng=-1 (the firmware's
%   "no previous position" sentinel) and is returned with NaN values
%   so the caller can detect the case unambiguously.

bytes = uint8(bytes(:)');
if numel(bytes) ~= 12
    error('firmware_eeprom_unpack:BadLength', ...
        'Expected 12 bytes, got %d.', numel(bytes));
end

latE6 = typecast(bytes(1:4),  'int32');
lngE6 = typecast(bytes(5:8),  'int32');
altCm = typecast(bytes(9:12), 'int32');

if latE6 == intmin('int32') || latE6 == -1 && lngE6 == -1
    latDeg = NaN; lngDeg = NaN; altMeters = NaN;
    return
end

latDeg    = double(latE6) / 1e6;
lngDeg    = double(lngE6) / 1e6;
altMeters = double(altCm) / 100;
end
