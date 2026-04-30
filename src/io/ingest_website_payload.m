function P = ingest_website_payload(cfg)
%INGEST_WEBSITE_PAYLOAD  Load 859-point UV / BMP390 telemetry from
%   the NASA-ASCEND-Website spring2026_payload.json export.
%
%   Returns a timetable with columns:
%     elapsed_s, alt_m, alt_ft, pressure_pa, temp_c,
%     uv1, uv2, uv3, uv4 (sums of A+B+C bands),
%     uv1a..uv4c (raw triads), uv_total (sum of 4 sensors)
%
%   This is the post-processed, denoised flight UV record used on
%   the public website and provides the primary photometric truth.

if ~isfile(cfg.files.web_payload)
    warning('website payload JSON not found: %s', cfg.files.web_payload);
    P = timetable();
    return
end

raw = jsondecode(fileread(cfg.files.web_payload));
S   = raw.data;
n   = numel(S);

flds = {'elapsed_s','uv1a','uv1b','uv1c','uv2a','uv2b','uv2c', ...
        'uv3a','uv3b','uv3c','uv4a','uv4b','uv4c', ...
        'pressure_pa','temp_c','alt_m','alt_ft','uv1','uv2','uv3','uv4'};
M = nan(n, numel(flds));
for k = 1:n
    s = S(k);
    for j = 1:numel(flds)
        f = flds{j};
        if isfield(s,f) && ~isempty(s.(f)), M(k,j) = double(s.(f)); end
    end
end

t  = cfg.mission.launch_time_utc + seconds(M(:,1));
P  = timetable(t);
for j = 1:numel(flds)
    P.(flds{j}) = M(:,j);
end
P.uv_total = P.uv1 + P.uv2 + P.uv3 + P.uv4;

P.Properties.UserData = struct( ...
    'source','NASA-ASCEND-Website / spring2026_payload.json', ...
    'flight', raw.flight, 'date', raw.date, ...
    'peak_alt_ft', raw.peak_alt_ft, ...
    'duration_min', raw.duration_min, 'points', raw.points);

fprintf('  ingest_website_payload : %d samples, %.1f min, peak %.0f ft\n', ...
    n, raw.duration_min, raw.peak_alt_ft);
end
