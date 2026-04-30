function track = compute_ground_track(D, cfg)
%COMPUTE_GROUND_TRACK  Reconstruct lat/lon ground track + Vincenty stats.
%
%   track = COMPUTE_GROUND_TRACK(D, cfg) takes the ingested data struct
%   and returns a timetable with t_s, lat, lon, alt_m, range_km,
%   bearing_deg (from launch), heading_deg (between consecutive points),
%   d_seg_km, v_lat_ms.

T = D.trajectory;
n = height(T);
[range_km, bearing, heading, d_seg_km, vlat_ms] = deal(nan(n,1));

lat0 = cfg.mission.launch_lat;
lon0 = cfg.mission.launch_lon;

for i = 1:n
    [d, az, ~] = wgs84_inverse(lat0, lon0, T.lat(i), T.lon(i));
    range_km(i) = d/1000;
    bearing(i)  = az;
    if i > 1
        [ds, hdg, ~] = wgs84_inverse(T.lat(i-1),T.lon(i-1),T.lat(i),T.lon(i));
        d_seg_km(i) = ds/1000;
        heading(i)  = hdg;
        dt = T.t_s(i) - T.t_s(i-1);
        if dt>0, vlat_ms(i) = ds/dt; end
    end
end

track = timetable(T.time_utc, T.t_s, T.lat, T.lon, T.alt_m, ...
    range_km, bearing, heading, d_seg_km, vlat_ms, ...
    'VariableNames',{'t_s','lat','lon','alt_m','range_km','bearing_deg','heading_deg','d_seg_km','vlat_ms'});
track.Properties.DimensionNames{1}='time_utc';
end
