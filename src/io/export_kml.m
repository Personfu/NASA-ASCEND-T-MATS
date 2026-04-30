function fp = export_kml(D, track, cfg)
%EXPORT_KML  Write a Google-Earth-ready KML of the Balloon-2 flight track.
%
%   fp = EXPORT_KML(D, track, cfg) writes "ASCEND_S26_flight.kml" into
%   cfg.paths.reports and returns the full path. The KML contains:
%       - the launch site placemark
%       - the apex placemark (burst)
%       - the landing placemark
%       - a 3D LineString colored by altitude
%       - sub-placemarks every 60 s with timestamps for the time slider
%
%   The track uses absolute altitude (relativeToGround would clip into
%   terrain because APRS altitudes are MSL).

T = D.trajectory;
lat = T.lat; lon = T.lon; alt = T.alt_m;
[apex_m, iA] = max(alt);
t_abs = cfg.mission.launch_time_utc + seconds(T.t_s);

fp = fullfile(cfg.paths.reports, 'ASCEND_S26_flight.kml');
fid = fopen(fp,'w'); oc = onCleanup(@() fclose(fid));

w = @(varargin) fprintf(fid, varargin{:});
w('<?xml version="1.0" encoding="UTF-8"?>\n');
w('<kml xmlns="http://www.opengis.net/kml/2.2"\n');
w('     xmlns:gx="http://www.google.com/kml/ext/2.2">\n');
w('<Document>\n');
w('  <name>Phoenix College ASCEND - Spring 2026 - Balloon 2</name>\n');
w('  <description><![CDATA[KA7NSR-15 / launched %s UTC]]></description>\n', ...
    datestr(cfg.mission.launch_time_utc,'yyyy-mm-dd HH:MM:SS'));

% styles
w('  <Style id="ascent"><LineStyle><color>ff%s</color><width>3</width></LineStyle></Style>\n', kml_hex([0.10 0.45 0.85]));
w('  <Style id="descent"><LineStyle><color>ff%s</color><width>3</width></LineStyle></Style>\n', kml_hex([0.85 0.20 0.20]));
w('  <Style id="launchPin"><IconStyle><color>ff00aa00</color><scale>1.2</scale></IconStyle></Style>\n');
w('  <Style id="apexPin"><IconStyle><color>ff00aaff</color><scale>1.4</scale></IconStyle></Style>\n');
w('  <Style id="landPin"><IconStyle><color>ff0000ff</color><scale>1.2</scale></IconStyle></Style>\n');

% placemarks
w('  <Placemark><name>Launch site</name><styleUrl>#launchPin</styleUrl>');
w('<Point><altitudeMode>absolute</altitudeMode><coordinates>%.6f,%.6f,%.1f</coordinates></Point></Placemark>\n', ...
    cfg.mission.launch_lon, cfg.mission.launch_lat, cfg.mission.launch_alt_m);

w('  <Placemark><name>Apex (burst, %.0f ft)</name><styleUrl>#apexPin</styleUrl>', apex_m/0.3048);
w('<TimeStamp><when>%s</when></TimeStamp>', datestr(t_abs(iA),'yyyy-mm-ddTHH:MM:SSZ'));
w('<Point><altitudeMode>absolute</altitudeMode><coordinates>%.6f,%.6f,%.1f</coordinates></Point></Placemark>\n', ...
    lon(iA), lat(iA), alt(iA));

w('  <Placemark><name>Landing</name><styleUrl>#landPin</styleUrl>');
w('<TimeStamp><when>%s</when></TimeStamp>', datestr(t_abs(end),'yyyy-mm-ddTHH:MM:SSZ'));
w('<Point><altitudeMode>absolute</altitudeMode><coordinates>%.6f,%.6f,%.1f</coordinates></Point></Placemark>\n', ...
    lon(end), lat(end), alt(end));

% ascent linestring
w('  <Placemark><name>Ascent</name><styleUrl>#ascent</styleUrl>\n');
w('    <LineString><extrude>1</extrude><tessellate>1</tessellate>\n');
w('      <altitudeMode>absolute</altitudeMode><coordinates>\n');
for k=1:iA, w('        %.6f,%.6f,%.1f\n', lon(k),lat(k),alt(k)); end
w('      </coordinates></LineString></Placemark>\n');

% descent linestring
w('  <Placemark><name>Descent</name><styleUrl>#descent</styleUrl>\n');
w('    <LineString><extrude>1</extrude><tessellate>1</tessellate>\n');
w('      <altitudeMode>absolute</altitudeMode><coordinates>\n');
for k=iA:numel(lat), w('        %.6f,%.6f,%.1f\n', lon(k),lat(k),alt(k)); end
w('      </coordinates></LineString></Placemark>\n');

% time-tagged track samples (every ~60 s)
ts = T.t_s; targets = 0:60:max(ts);
w('  <Folder><name>Time samples</name>\n');
for tt = targets
    [~,k] = min(abs(ts-tt));
    w('    <Placemark><name>T+%d s | %.0f m</name>', round(tt), alt(k));
    w('<TimeStamp><when>%s</when></TimeStamp>', datestr(t_abs(k),'yyyy-mm-ddTHH:MM:SSZ'));
    w('<Point><altitudeMode>absolute</altitudeMode><coordinates>%.6f,%.6f,%.1f</coordinates></Point>', ...
        lon(k), lat(k), alt(k));
    w('</Placemark>\n');
end
w('  </Folder>\n');

w('</Document></kml>\n');
fprintf('  KML written -> %s\n', fp);

if exist('track','var') && ~isempty(track) && isfield(track,'range_km')
    fprintf('  (apex %.1f km, landing %.1f km from launch)\n', ...
        track.range_km(iA), track.range_km(end));
end
end

function s = kml_hex(rgb)
% KML uses aabbggrr (alpha first, BGR after)
b = round(rgb(3)*255); g = round(rgb(2)*255); r = round(rgb(1)*255);
s = sprintf('%02x%02x%02x', b, g, r);
end
