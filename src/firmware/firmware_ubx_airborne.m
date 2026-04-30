function [packet, ckA, ckB] = firmware_ubx_airborne()
%FIRMWARE_UBX_AIRBORNE  Build the UBX-CFG-NAV5 Airborne <1g> packet.
%
%   [PACKET, CKA, CKB] = FIRMWARE_UBX_AIRBORNE() returns the 44-byte
%   UBX-CFG-NAV5 packet that the firmware sends to the VK2828U7G5LF
%   (u-blox G7020) at boot. PACKET is uint8(1,44). The Fletcher-8
%   checksum (CKA, CKB) is computed over bytes 2..41 inclusive.
%
%   The packet sets dynModel = 6 (Airborne <1 g>), raising the COCOM
%   altitude ceiling from ~12 km to 50 km. Without it the GPS silently
%   stops reporting position above ~12 km.
%
%   This MATLAB helper exactly mirrors the bytes emitted by
%   `configureGPSAirborne()` in HailMaryV1f.ino so a ground-station
%   tool can validate or replay the same configuration over a USB
%   serial bridge.

payload = uint8([ ...
    hex2dec('B5'), hex2dec('62'), ...   % sync
    hex2dec('06'), hex2dec('24'), ...   % CFG-NAV5
    hex2dec('24'), hex2dec('00'), ...   % length 36
    hex2dec('FF'), hex2dec('FF'), ...   % mask: apply all
    hex2dec('06'), ...                  % dynModel = Airborne <1g>
    hex2dec('03'), ...                  % fixMode = auto 2D/3D
    0,0,0,0, ...                        % fixedAlt
    hex2dec('10'), hex2dec('27'), 0, 0, ...   % fixedAltVar
    hex2dec('05'), ...                  % minElev
    0, ...                              % drLimit
    hex2dec('FA'), hex2dec('00'), ...   % pDop = 25.0
    hex2dec('FA'), hex2dec('00'), ...   % tDop = 25.0
    hex2dec('64'), hex2dec('00'), ...   % pAcc = 100 m
    hex2dec('2C'), hex2dec('01'), ...   % tAcc = 300 m
    0, ...                              % staticHoldThresh
    0, ...                              % dgnssTimeout
    0,0,0,0, ...                        % cnoThreshNumSVs, cnoThresh, reserved
    0,0, ...                            % staticHoldMaxDist
    0, ...                              % utcStandard
    0,0,0,0,0]);                        % reserved

ckA = uint8(0); ckB = uint8(0);
for i = 3:42                            % MATLAB 1-based: bytes 3..42 == C 2..41
    ckA = uint8(mod(uint16(ckA) + uint16(payload(i)), 256));
    ckB = uint8(mod(uint16(ckB) + uint16(ckA), 256));
end

packet = uint8([payload, ckA, ckB]);
end
