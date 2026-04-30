function fp = write_html_dashboard(D, sim, MC, link, val, E, FD, PS, cfg)
%WRITE_HTML_DASHBOARD  Generate a self-contained HTML mission dashboard.
%
%   Produces reports/ASCEND_S26_dashboard.html, a single file that links
%   into the figures/*.png catalog and embeds the mission summary tables
%   so the ASCEND team can share a polished mission read-out without
%   running MATLAB.

T = D.trajectory;
[apex_m, iA] = max(T.alt_m);

fp = fullfile(cfg.paths.reports, 'ASCEND_S26_dashboard.html');
fid = fopen(fp,'w'); oc = onCleanup(@() fclose(fid));
w = @(varargin) fprintf(fid, varargin{:});

w('<!doctype html><html><head><meta charset="utf-8">\n');
w('<title>ASCEND Spring 2026 Mission Dashboard</title>\n');
w('<style>\n');
w(' body{font-family:Helvetica,Arial,sans-serif;background:#0f1115;color:#e8e8e8;margin:0;padding:24px;}\n');
w(' h1{color:#5dd2ff;margin-bottom:0;} h2{color:#ffc857;margin-top:32px;}\n');
w(' .card{background:#1a1d24;border:1px solid #2a2f3a;border-radius:10px;padding:16px 20px;margin:14px 0;}\n');
w(' .grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(360px,1fr));gap:14px;}\n');
w(' .kv{display:grid;grid-template-columns:200px 1fr;gap:6px;}\n');
w(' .kv b{color:#9bd1ff;}\n');
w(' table{border-collapse:collapse;width:100%%;margin-top:8px;}\n');
w(' td,th{border:1px solid #2a2f3a;padding:6px 10px;text-align:left;}\n');
w(' th{background:#23283a;color:#5dd2ff;}\n');
w(' img{width:100%%;border-radius:6px;border:1px solid #2a2f3a;}\n');
w(' .ok{color:#7bdc91;} .warn{color:#ffb066;} .bad{color:#ff7373;}\n');
w('</style></head><body>\n');

w('<h1>Phoenix College NASA ASCEND - Spring 2026</h1>\n');
w('<div class="kv"><b>Balloon</b><span>%s</span>', cfg.mission.balloon_id);
w('<b>Callsign</b><span>%s</span>', cfg.mission.aprs_callsign);
w('<b>Launch UTC</b><span>%s</span>', datestr(cfg.mission.launch_time_utc,'yyyy-mm-dd HH:MM:SS'));
w('<b>Launch Lat/Lon</b><span>%.5f, %.5f</span>', cfg.mission.launch_lat, cfg.mission.launch_lon);
w('<b>Launch Alt</b><span>%.0f m / %.0f ft MSL</span>', cfg.mission.launch_alt_m, cfg.mission.launch_alt_m/0.3048);
w('<b>Apex (flight)</b><span>%.0f m / %.0f ft @ T+%.1f min</span>', apex_m, apex_m/0.3048, T.t_s(iA)/60);
w('<b>Flight duration</b><span>%.1f min</span>', max(T.t_s)/60);
w('</div>\n');

% --- key metrics
w('<h2>Mission Metrics</h2><div class="grid">\n');
metric_card(w, 'Trajectory', { ...
    sprintf('apex: %.0f m', apex_m), ...
    sprintf('peak ascent: %.1f mph', max(T.vz_mph,[],'omitnan')), ...
    sprintf('peak descent: %.1f mph', min(T.vz_mph,[],'omitnan')), ...
    sprintf('impact: %.1f mph', cfg.mission.impact_mph)});
if ~isempty(FD) && isfield(FD.Properties,'UserData')
    ud = FD.Properties.UserData;
    metric_card(w, 'Aerodynamics', { ...
        sprintf('q_max: %.1f Pa @ T+%.0f s', ud.q_max_Pa, ud.q_max_when), ...
        sprintf('M_max: %.3f', ud.M_max), ...
        sprintf('Re_max: %.2e', ud.Re_max), ...
        sprintf('Apex PE: %.0f kJ', ud.PE_apex_J/1e3)});
end
if ~isempty(MC) && isfield(MC,'cep50_km') && MC.N>0
    metric_card(w, 'Dispersion', { ...
        sprintf('CEP50: %.2f km', MC.cep50_km), ...
        sprintf('CEP95: %.2f km', MC.cep95_km), ...
        sprintf('Monte Carlo runs: %d', MC.N)});
end
if ~isempty(link)
    metric_card(w, 'APRS Link', { ...
        sprintf('range max: %.1f km', max(link.d_km,[],'omitnan')), ...
        sprintf('worst margin: %.1f dB', min(link.link_margin_dB,[],'omitnan')), ...
        sprintf('mean SNR: %.1f dB', mean(link.snr_dB,'omitnan'))});
end
if ~isempty(PS)
    metric_card(w, 'Payload', { ...
        sprintf('flight mass: %.0f g', PS.totals.flight_mass_g), ...
        sprintf('CG: [%+.0f, %+.0f, %+.0f] mm', PS.totals.cg_m*1000), ...
        sprintf('FAA Part 101: %s', ternary(PS.faa.compliant,'<span class="ok">COMPLIANT</span>','<span class="bad">VIOLATION</span>')), ...
        sprintf('areal density: %.3f psi', PS.faa.areal_density_psi)});
end
w('</div>\n');

% --- events
if ~isempty(E) && isfield(E,'summary_table')
    w('<h2>Flight Events</h2><div class="card">\n');
    Tab = E.summary_table;
    w('<table><tr><th>Event</th><th>T+ (s)</th><th>Altitude (m)</th><th>Description</th></tr>\n');
    for k=1:height(Tab)
        w('<tr><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>\n', ...
            char(Tab.event(k)), num2str_or(Tab.t_s(k)), num2str_or(Tab.alt_m(k)), char(Tab.description(k)));
    end
    w('</table></div>\n');
end

% --- validation
if ~isempty(val) && isfield(val,'summary_table')
    w('<h2>Model Validation</h2><div class="card">\n');
    Tab = val.summary_table;
    w('<table>'); w('<tr>');
    for k=1:width(Tab), w('<th>%s</th>', Tab.Properties.VariableNames{k}); end
    w('</tr>');
    for r=1:height(Tab)
        w('<tr>');
        for k=1:width(Tab)
            v = Tab.(Tab.Properties.VariableNames{k})(r);
            if isnumeric(v), w('<td>%.4g</td>', v); else, w('<td>%s</td>', char(string(v))); end
        end
        w('</tr>');
    end
    w('</table></div>\n');
end

% --- figures
w('<h2>Dashboards</h2><div class="grid">\n');
figs = {'01_trajectory_dashboard','02_atmosphere','03_science','04_imu', ...
        '05_simulation','06_thermal_power','07_3d_globe','08_payload', ...
        '09_phase_timeline','10_aerodynamics','11_dispersion','12_link_budget','13_wind_profile'};
captions = {'Trajectory','Atmosphere vs sensors','Science payload','IMU/Mag', ...
            'Sim vs flight','Thermal & Power','3D globe','Payload mass props', ...
            'Phase timeline','Aerodynamics','Dispersion','APRS link','Wind profile'};
for k=1:numel(figs)
    img = fullfile(cfg.paths.figures, [figs{k},'.png']);
    if exist(img,'file')
        rel = relpath(img, fileparts(fp));
        w('<div class="card"><b>%s</b><br><img src="%s"/></div>\n', captions{k}, rel);
    end
end
w('</div>\n');

w('<h2>Files</h2><div class="card kv">\n');
emit_link(w, 'KML (Google Earth)', fullfile(cfg.paths.reports,'ASCEND_S26_flight.kml'), fileparts(fp));
emit_link(w, 'GPX (chase tools)',  fullfile(cfg.paths.reports,'ASCEND_S26_flight.gpx'), fileparts(fp));
emit_link(w, 'Mission report',     fullfile(cfg.paths.reports,'ASCEND_S26_MISSION_REPORT.md'), fileparts(fp));
emit_link(w, 'Text summary',       fullfile(cfg.paths.reports,'ASCEND_S26_summary.txt'), fileparts(fp));
w('</div>\n');

w('<p style="color:#888;margin-top:30px;">Generated %s by ASCEND-S26 / Personfu.</p>\n', datestr(now));
w('</body></html>\n');
fprintf('  HTML dashboard -> %s\n', fp);
end

function metric_card(w, title, lines)
w('<div class="card"><b>%s</b><ul>', title);
for k=1:numel(lines), w('<li>%s</li>', lines{k}); end
w('</ul></div>');
end

function s = num2str_or(v), if isnan(v), s=''; else, s=sprintf('%.1f',v); end, end

function emit_link(w, label, fpath, base)
if exist(fpath,'file')
    rel = relpath(fpath, base);
    w('<b>%s</b><span><a style="color:#5dd2ff" href="%s">%s</a></span>', label, rel, rel);
end
end

function rel = relpath(target, base)
% windows-friendly relative path
rel = strrep(target, [base filesep], '');
rel = strrep(rel, '\','/');
end

function out = ternary(c,a,b), if c, out=a; else, out=b; end, end
