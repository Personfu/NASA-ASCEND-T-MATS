function [hits, mag] = firmware_detect_impact(accel, phase, threshold)
%FIRMWARE_DETECT_IMPACT  Re-run the V1f impact detector on logged accel data.
%
%   [HITS, MAG] = FIRMWARE_DETECT_IMPACT(ACCEL, PHASE) takes an Nx3
%   acceleration matrix in m/s^2 (columns ax, ay, az), the matching
%   uint8 PHASE vector from the firmware, and returns:
%
%       MAG  - vector of acceleration magnitudes (sqrt(ax^2+ay^2+az^2))
%       HITS - logical vector marking samples where MAG > threshold
%              AND phase >= DESCENT (the firmware only arms the detector
%              once the payload is descending).
%
%   FIRMWARE_DETECT_IMPACT(ACCEL, PHASE, THRESHOLD) overrides the
%   default 147 m/s^2 (~15 g) IMPACT_THRESHOLD_MS2 from the AVR source.
%
%   This MATLAB twin lets you scan a recovered `asusux.csv` for the same
%   impact event the firmware would have caught, validating that the
%   on-board emergency flush was triggered at the right moment.

if nargin < 3 || isempty(threshold), threshold = 147.0; end
if nargin < 2 || isempty(phase)
    phase = repmat(uint8(3), size(accel,1), 1);  % assume DESCENT armed
end

mag = sqrt(sum(double(accel).^2, 2));
armed = uint8(phase) >= 3;
hits = armed & (mag > threshold);
end
