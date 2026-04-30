function A = ingest_website_aprs(cfg)
%INGEST_WEBSITE_APRS  Load APRS truth track from NASA ASCEND website
%   spring2026_aprs_track.json export (144 fixes, KA7NSR-15).
%
%   Out:  A.stats   - mission summary (peak alt, distance, rates...)
%         A.launch  - [lat lon] (deg)
%         A.landing - [lat lon] (deg)
%         A.tt      - timetable of fixes with phase tag
%         A.burst_time_utc

A = struct('stats',struct(),'tt',timetable());
if ~isfile(cfg.files.web_aprs)
    warning('website APRS JSON not found: %s', cfg.files.web_aprs); return
end
raw = jsondecode(fileread(cfg.files.web_aprs));
A.stats   = raw.stats;
A.launch  = double(raw.launch_coords(:)).';
A.landing = double(raw.landing_coords(:)).';
A.callsign= raw.callsign;
try
    A.burst_time_utc = datetime(raw.stats.burst_time, ...
        'InputFormat','yyyy-MM-dd HH:mm:ss','TimeZone','UTC');
catch
    A.burst_time_utc = NaT('TimeZone','UTC');
end

S = raw.track; n = numel(S);
fl = {'elapsed_s','lat','lng','alt_m','alt_ft','speed_kmh','speed_mph', ...
      'vert_rate_ms','vert_rate_fts','temp_c','vbat','pressure_pa','cum_dist_km'};
M = nan(n, numel(fl));
phase = strings(n,1);
for k = 1:n
    for j = 1:numel(fl)
        f = fl{j};
        if isfield(S(k),f) && ~isempty(S(k).(f)) && isnumeric(S(k).(f))
            M(k,j) = double(S(k).(f));
        end
    end
    if isfield(S(k),'phase'), phase(k) = string(S(k).phase); end
end
t = cfg.mission.launch_time_utc + seconds(M(:,1));
A.tt = timetable(t);
for j = 1:numel(fl); A.tt.(fl{j}) = M(:,j); end
A.tt.phase = phase;

A.tt.Properties.UserData = struct( ...
    'source','NASA-ASCEND-Website / spring2026_aprs_track.json', ...
    'callsign', A.callsign, ...
    'launch_coords', A.launch, 'landing_coords', A.landing);

fprintf('  ingest_website_aprs    : %d fixes, peak %.0f m, dist %.1f km\n', ...
    n, A.stats.peak_altitude_m, A.stats.total_ground_distance_km);
end
