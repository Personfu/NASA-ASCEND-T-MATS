function T = ingest_trajectory(cfg)
%INGEST_TRAJECTORY  Parse Balloon-2 APRS-derived trajectory CSV.
%
%   T = INGEST_TRAJECTORY(cfg) returns a timetable with columns:
%       t_utc        datetime (UTC)
%       t_s          elapsed seconds since release
%       lat,lon      WGS84 deg
%       alt_m        geometric altitude MSL (m)
%       alt_ft       feet
%       gs_mph       APRS reported ground speed
%       course_deg   APRS course
%       vz_fps,vz_ms vertical speed
%       az_g         vertical acceleration in g
%       phase        categorical {launch,ascent,burst,descent,landed}
%
%   Source: KA7NSR-15 APRS log + spreadsheet parameterization (E. Whittenburg).

raw = readcell(cfg.files.trajectory);
% Row 1 = title, row 2 = section labels, row 3 = column headers (incl. units), row 4+ = data
hdr = string(raw(3,:));
data = raw(4:end,:);
% readcell returns 'missing' for empty cells; convert to "" for contains()
hdr(ismissing(hdr)) = "";

% Locate columns by header keyword
col = @(k) find(contains(lower(hdr), lower(k)), 1, 'first');
ic_time = col("time");
ic_lat  = col("lat");
ic_lon  = col("lng");
ic_spd  = col("speed");
ic_crs  = col("course");
ic_altm = col("altitude (m)");
ic_etot = find(strcmp(strtrim(hdr),"total sec"),1);
ic_etps = find(strcmp(strtrim(hdr),"(sec)"),1);
ic_altf = find(strcmp(strtrim(hdr),"(ft)"),1);
ic_vfps = find(strcmp(strtrim(hdr),"(ft/s)"),1);
ic_vmph = find(strcmp(strtrim(hdr),"(mph)"),1);
ic_afps = find(strcmp(strtrim(hdr),"(ft/s2)"),1);
ic_g    = find(strcmp(strtrim(hdr),"Gs"),1);

n = size(data,1);
t_utc = NaT(n,1,'TimeZone','UTC');
[lat,lon,alt_m,gs_mph,course_deg,t_s,alt_ft,vz_fps,vz_mph,az_fps2,az_g] = deal(nan(n,1));

for i = 1:n
    tv = data{i,ic_time};
    if ischar(tv) || isstring(tv)
        try, t_utc(i) = datetime(tv,'InputFormat','yyyy-MM-dd HH:mm:ss','TimeZone','UTC'); catch, end
    elseif isa(tv,'datetime')
        t_utc(i) = tv; t_utc(i).TimeZone = 'UTC';
    end
    lat(i)        = num(data{i,ic_lat});
    lon(i)        = num(data{i,ic_lon});
    alt_m(i)      = num(data{i,ic_altm});
    gs_mph(i)     = num(data{i,ic_spd});
    course_deg(i) = num(data{i,ic_crs});
    t_s(i)        = num(data{i,ic_etps});
    alt_ft(i)     = num(data{i,ic_altf});
    vz_fps(i)     = num(data{i,ic_vfps});
    vz_mph(i)     = num(data{i,ic_vmph});
    az_fps2(i)    = num(data{i,ic_afps});
    az_g(i)       = num(data{i,ic_g});
end

% Drop completely empty trailing rows
keep = ~isnat(t_utc) & ~isnan(alt_m);
t_utc=t_utc(keep); lat=lat(keep); lon=lon(keep); alt_m=alt_m(keep);
gs_mph=gs_mph(keep); course_deg=course_deg(keep);
t_s=t_s(keep); alt_ft=alt_ft(keep); vz_fps=vz_fps(keep);
vz_mph=vz_mph(keep); az_fps2=az_fps2(keep); az_g=az_g(keep);

vz_ms = vz_fps*0.3048;

% Phase classification
phase = repmat("ascent", numel(alt_m), 1);
[apex,iApex] = max(alt_m);
phase(1:max(1,find(alt_m>cfg.mission.launch_alt_m+10,1)-1)) = "launch";
phase(iApex) = "burst";
phase(iApex+1:end) = "descent";
% landed if final altitude near launch
if alt_m(end) < cfg.mission.launch_alt_m + 200
    iLand = find(alt_m < cfg.mission.launch_alt_m+50, 1, 'last');
    phase(iLand:end) = "landed";
end

T = timetable(t_utc, t_s, lat, lon, alt_m, alt_ft, gs_mph, course_deg, ...
              vz_fps, vz_ms, vz_mph, az_fps2, az_g, categorical(phase), ...
              'VariableNames', {'t_s','lat','lon','alt_m','alt_ft', ...
                                'gs_mph','course_deg','vz_fps','vz_ms', ...
                                'vz_mph','az_fps2','az_g','phase'});
T.Properties.DimensionNames{1} = 'time_utc';
T.Properties.UserData.apex_m = apex;
T.Properties.UserData.apex_idx = iApex;
end

function v = num(x)
if isnumeric(x), v = double(x);
elseif ischar(x) || isstring(x)
    v = str2double(x); if isnan(v), v = NaN; end
else, v = NaN;
end
end
