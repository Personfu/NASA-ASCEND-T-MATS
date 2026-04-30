function eepromBytes = firmware_eeprom_pack(latDeg, lngDeg, altMeters)
%FIRMWARE_EEPROM_PACK  Build the 12-byte EEPROM block written by V1f.
%
%   BYTES = FIRMWARE_EEPROM_PACK(LATDEG, LNGDEG, ALTM) returns a
%   uint8(1,12) buffer formatted exactly like the firmware writes via
%   EEPROM.put() at address EEPROM_GPS_ADDR = 0:
%
%       0..3  : int32  latE6 = round(lat * 1e6)
%       4..7  : int32  lngE6 = round(lng * 1e6)
%       8..11 : int32  altCm = round(alt * 100)
%
%   The integers are encoded little-endian to match the AVR memory
%   layout. FIRMWARE_EEPROM_UNPACK reverses this transformation.

latE6 = int32(round(double(latDeg) * 1e6));
lngE6 = int32(round(double(lngDeg) * 1e6));
altCm = int32(round(double(altMeters) * 100));

eepromBytes = uint8([typecast(latE6, 'uint8'), ...
                     typecast(lngE6, 'uint8'), ...
                     typecast(altCm, 'uint8')]);
end
