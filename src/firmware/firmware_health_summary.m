function S = firmware_health_summary(T)
%FIRMWARE_HEALTH_SUMMARY  Summarise sensor health from a decoded V1f run.
%
%   S = FIRMWARE_HEALTH_SUMMARY(T) takes the timetable returned by
%   FIRMWARE_DECODE_CSV and produces a struct with:
%
%       .uptimePct     - 1x8 vector of % time each sensor reported up
%                        in the order [UV1 UV2 UV3 UV4 BMP BNO SD GPS]
%       .uptimeNames   - matching cellstr of channel labels
%       .meanFreeRam   - mean free SRAM (bytes)
%       .minFreeRam    - minimum free SRAM (bytes)
%       .maxStaleBmp   - longest BMP stale streak
%       .maxStaleBno   - longest BNO stale streak
%       .calMode       - mode of the BNO055 sys-cal value (0..3)
%       .phaseDuration - struct with seconds spent in each phase
%       .impactRows    - row indices flagged by the in-firmware detector
%
%   This produces the canonical post-flight health snapshot used in the
%   payload engineering report.

if ~istimetable(T)
    error('firmware_health_summary:NotTimetable', ...
        'Input must be the timetable returned by firmware_decode_csv.');
end

names = {'UV1','UV2','UV3','UV4','BMP','BNO','SD','GPS'};
flags = [T.h_UV1, T.h_UV2, T.h_UV3, T.h_UV4, ...
         T.h_BMP, T.h_BNO, T.h_SD,  T.h_GPS];
S.uptimeNames = names;
S.uptimePct   = 100 * mean(double(flags), 1);

S.meanFreeRam = mean(T.free_ram, 'omitnan');
S.minFreeRam  = min(T.free_ram, [], 'omitnan');
S.maxStaleBmp = max(T.stale_bmp, [], 'omitnan');
S.maxStaleBno = max(T.stale_bno, [], 'omitnan');
S.calMode     = mode(T.cal_sys);

% Time per phase
phaseSecs = struct();
phases = {'ground','ascent','float','descent','landed'};
dt = seconds(median(diff(T.Properties.RowTimes), 'omitnan'));
if isnan(dt) || dt <= 0, dt = 0.5; end  % fallback to writeInterval=500ms
for k = 1:numel(phases)
    phaseSecs.(phases{k}) = dt * sum(T.phase_label == phases{k});
end
S.phaseDuration = phaseSecs;

% Re-run impact detector against logged accel + phase
accel = [T.accelX, T.accelY, T.accelZ];
hits  = firmware_detect_impact(accel, T.phase);
S.impactRows = find(hits);
end
