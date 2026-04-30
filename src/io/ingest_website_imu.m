function I = ingest_website_imu(cfg)
%INGEST_WEBSITE_IMU  Load public IMU samples and summary from the
%   NASA ASCEND website spring2026_imu_public.json export.
%
%   Out:  I.summary  - struct of headline statistics
%         I.tt       - timetable of 160 published samples
%                      (elapsed_s, alt_ft, g_load, accel_ms2,
%                       temp_c, pressure_torr, uv_total)
%
%   These are the headline IMU records released for outreach.
%   Provides ground truth for max-g event, Pfotzer alignment,
%   and pressure/temperature minima.

I = struct('summary',struct(),'tt',timetable());
if ~isfile(cfg.files.web_imu)
    warning('website IMU JSON not found: %s', cfg.files.web_imu); return
end
raw = jsondecode(fileread(cfg.files.web_imu));
I.summary = raw.summary;

S = raw.samples; n = numel(S);
fl = {'elapsed_s','alt_ft','g_load','accel_ms2','temp_c','pressure_torr','uv_total'};
M = nan(n, numel(fl));
for k = 1:n
    for j = 1:numel(fl)
        f = fl{j};
        if isfield(S(k),f) && ~isempty(S(k).(f)), M(k,j) = double(S(k).(f)); end
    end
end
t = cfg.mission.launch_time_utc + seconds(M(:,1));
I.tt = timetable(t);
for j = 1:numel(fl); I.tt.(fl{j}) = M(:,j); end
I.tt.alt_m       = M(:,2) * 0.3048;
I.tt.pressure_pa = M(:,6) * 133.322368;     % torr -> Pa

I.tt.Properties.UserData = struct( ...
    'source','NASA-ASCEND-Website / spring2026_imu_public.json', ...
    'public_release', raw.public_release);

fprintf('  ingest_website_imu     : %d samples, max g=%.2f at %.0f ft\n', ...
    n, I.summary.max_g_load, I.summary.max_g_alt_ft);
end
