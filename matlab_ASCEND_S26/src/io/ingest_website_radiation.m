function R = ingest_website_radiation(cfg)
%INGEST_WEBSITE_RADIATION  Load public Geiger samples and summary
%   from the NASA ASCEND website spring2026_radiation_public.json export.
%
%   Out:  R.summary  - struct (peak CPM, peak uSv/h, Pfotzer altitude...)
%         R.tt       - timetable of 88 published samples with phase tag

R = struct('summary',struct(),'tt',timetable());
if ~isfile(cfg.files.web_radiation)
    warning('website radiation JSON not found: %s', cfg.files.web_radiation); return
end
raw = jsondecode(fileread(cfg.files.web_radiation));
R.summary    = raw.summary;
R.alignment  = raw.alignment_note;

S = raw.samples; n = numel(S);
fl = {'elapsed_s','seconds_day','alt_ft','cpm','usv_h'};
M  = nan(n, numel(fl));
phase = strings(n,1);
for k = 1:n
    for j = 1:numel(fl)
        f = fl{j};
        if isfield(S(k),f) && ~isempty(S(k).(f)), M(k,j) = double(S(k).(f)); end
    end
    if isfield(S(k),'phase'), phase(k) = string(S(k).phase); end
end
t = cfg.mission.launch_time_utc + seconds(M(:,1));
R.tt = timetable(t);
for j = 1:numel(fl); R.tt.(fl{j}) = M(:,j); end
R.tt.alt_m = M(:,3) * 0.3048;
R.tt.phase = phase;

R.tt.Properties.UserData = struct( ...
    'source','NASA-ASCEND-Website / spring2026_radiation_public.json', ...
    'public_release', raw.public_release);

fprintf('  ingest_website_rad     : %d samples, peak %.0f CPM (%.3f uSv/h) @ %.0f ft\n', ...
    n, R.summary.peak_cpm, R.summary.peak_usv_h, R.summary.peak_radiation_alt_ft);
end
