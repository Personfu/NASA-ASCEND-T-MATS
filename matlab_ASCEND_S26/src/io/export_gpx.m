function fp = export_gpx(D, cfg)
%EXPORT_GPX  Write a GPX 1.1 track file of the Balloon-2 flight.
%
%   GPX is the universal interchange format for chase-team navigation
%   tools (Garmin, Locus, Gaia, etc.) and online viewers (gpx.studio,
%   GPSVisualizer). One <trk> with two <trkseg> sections (ascent +
%   descent), each <trkpt> tagged with <ele> (m), <time> (UTC ISO-8601),
%   and an <extensions> block carrying APRS-derived speed and course.

T = D.trajectory;
[~, iA] = max(T.alt_m);
t_abs = cfg.mission.launch_time_utc + seconds(T.t_s);

fp = fullfile(cfg.paths.reports, 'ASCEND_S26_flight.gpx');
fid = fopen(fp,'w'); oc = onCleanup(@() fclose(fid));
w = @(varargin) fprintf(fid, varargin{:});

w('<?xml version="1.0" encoding="UTF-8"?>\n');
w('<gpx version="1.1" creator="ASCEND-S26 (Personfu)"\n');
w('     xmlns="http://www.topografix.com/GPX/1/1">\n');
w('  <metadata>\n');
w('    <name>Phoenix College ASCEND - Spring 2026 - Balloon 2</name>\n');
w('    <time>%s</time>\n', datestr(cfg.mission.launch_time_utc,'yyyy-mm-ddTHH:MM:SSZ'));
w('    <desc>APRS-derived flight track, 1500g latex sounding balloon</desc>\n');
w('  </metadata>\n');

% waypoints (launch / apex / landing)
emit_wpt(w, cfg.mission.launch_lat, cfg.mission.launch_lon, cfg.mission.launch_alt_m, ...
         t_abs(1), 'Launch site');
emit_wpt(w, T.lat(iA), T.lon(iA), T.alt_m(iA), t_abs(iA), ...
         sprintf('Apex - %.0f ft', T.alt_m(iA)/0.3048));
emit_wpt(w, T.lat(end), T.lon(end), T.alt_m(end), t_abs(end), 'Landing');

% track
w('  <trk>\n');
w('    <name>Balloon 2 (KA7NSR-15)</name>\n');

% ascent segment
w('    <trkseg>\n');
emit_seg(w, T, t_abs, 1, iA);
w('    </trkseg>\n');

% descent segment
w('    <trkseg>\n');
emit_seg(w, T, t_abs, iA, height(T));
w('    </trkseg>\n');

w('  </trk>\n</gpx>\n');
fprintf('  GPX written -> %s\n', fp);
end

function emit_wpt(w, lat, lon, ele, t, name)
w('  <wpt lat="%.6f" lon="%.6f">\n', lat, lon);
w('    <ele>%.1f</ele>\n', ele);
w('    <time>%s</time>\n', datestr(t,'yyyy-mm-ddTHH:MM:SSZ'));
w('    <name>%s</name>\n', name);
w('  </wpt>\n');
end

function emit_seg(w, T, t_abs, i1, i2)
for k = i1:i2
    w('      <trkpt lat="%.6f" lon="%.6f"><ele>%.1f</ele><time>%s</time>', ...
        T.lat(k), T.lon(k), T.alt_m(k), datestr(t_abs(k),'yyyy-mm-ddTHH:MM:SSZ'));
    w('<extensions><gs_mph>%.2f</gs_mph><course_deg>%.1f</course_deg><vz_ms>%.2f</vz_ms></extensions>', ...
        nz(T.gs_mph(k)), nz(T.course_deg(k)), nz(T.vz_ms(k)));
    w('</trkpt>\n');
end
end

function v = nz(x), if isnan(x), v = 0; else, v = x; end, end
