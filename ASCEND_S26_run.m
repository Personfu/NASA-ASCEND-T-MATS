function results = ASCEND_S26_run(varargin)
%ASCEND_S26_RUN  Master driver for Phoenix College NASA ASCEND Spring 2026.
%
%   ASCEND_S26_RUN()                  - run full pipeline
%   ASCEND_S26_RUN('NoSim',true)      - skip ascent/descent simulation
%   ASCEND_S26_RUN('Quick',true)      - skip thermal/power
%
%   Outputs: figures/*.png, reports/ASCEND_S26_summary.txt,
%            data/processed/*.mat
%
%   Author : Personfu / Phoenix College NASA ASCEND
%   Mission: Balloon 2  -  Launched 2026-03-28 16:38:54 UTC
%
%   Pipeline:
%       1) Load configuration
%       2) Ingest 5 raw datasets -> timetables
%       3) Simulate ascent (US-1976 + ideal-gas balloon, RK4)
%       4) Simulate descent (parachute, RK4)
%       5) Reconstruct ground track (Vincenty inverse on WGS-84)
%       6) Run thermal model (lumped capacitance, 6 heat sources)
%       7) Run power budget (coulomb counting + thermostatic heater)
%       8) Run science models (Pfotzer, UV/ozone)
%       9) Generate 7 dashboards (PNG + PDF)
%      10) Write summary report

opts = struct('NoSim',false, 'Quick',false);
for k=1:2:numel(varargin), opts.(varargin{k}) = varargin{k+1}; end

% --- paths
this = fileparts(mfilename('fullpath'));
addpath(this);
addpath(fullfile(this,'config'));
addpath(genpath(fullfile(this,'src')));

cfg = ASCEND_S26_config();

banner();

% --- ingest
fprintf('\n=== INGEST RAW DATA ===\n');
D = ingest_all(cfg);

% --- ground track (Vincenty)
fprintf('\n=== GROUND TRACK (Vincenty inverse) ===\n');
track = compute_ground_track(D, cfg);
save(fullfile(cfg.paths.data_proc,'ground_track.mat'),'track');
fprintf('  apex range: %.2f km, max ground range: %.2f km, landing range: %.2f km\n', ...
    track.range_km(D.trajectory.Properties.UserData.apex_idx), max(track.range_km), track.range_km(end));

% --- simulation
sim = struct();
if ~opts.NoSim
    fprintf('\n=== ASCENT SIMULATION (US-1976 + ideal-gas) ===\n');
    sim.ascent  = simulate_ascent(cfg);
    fprintf('  apex t = %.0f s (%.1f min), apex h = %.0f m (%.0f ft)\n', ...
        sim.ascent.Properties.UserData.apex_t_s, sim.ascent.Properties.UserData.apex_t_s/60, ...
        sim.ascent.Properties.UserData.apex_m, sim.ascent.Properties.UserData.apex_m/0.3048);

    fprintf('\n=== DESCENT SIMULATION (parachute, RK4) ===\n');
    t_apex = sim.ascent.Properties.UserData.apex_t_s;
    sim.descent = simulate_descent(cfg, t_apex, sim.ascent.Properties.UserData.apex_m);
    fprintf('  peak descent: %.1f mph,  impact: %.1f mph (target %.1f mph)\n', ...
        sim.descent.Properties.UserData.peak_v_mph, sim.descent.Properties.UserData.impact_v_mph, ...
        cfg.mission.impact_mph);
    save(fullfile(cfg.paths.data_proc,'simulation.mat'),'sim');
end

% --- thermal & power
thermal = []; power = [];
if ~opts.Quick && ~opts.NoSim
    fprintf('\n=== THERMAL MODEL ===\n');
    traj = [sim.ascent(:,{'alt_m','v_ms'}); sim.descent(:,{'alt_m','v_ms'})];
    traj.t_s = seconds(traj.t);
    thermal = simulate_thermal(cfg, traj);
    fprintf('  T_box range: [%.1f , %.1f] C, heater duty: %.1f%%\n', ...
        min(thermal.T_box_C), max(thermal.T_box_C), 100*mean(thermal.heater_on));

    fprintf('\n=== POWER BUDGET ===\n');
    power = simulate_power(cfg, thermal);
    fprintf('  Energy used: %.2f Wh of %.2f Wh (DoD %.1f%%)\n', ...
        max(power.energy_used_Wh), cfg.power.pack_energy_Wh, max(power.DoD_pct));

    save(fullfile(cfg.paths.data_proc,'thermal_power.mat'),'thermal','power');
end

% --- payload bill of materials
fprintf('\n=== PAYLOAD SYSTEMS ===\n');
PS = payload_systems();
fprintf('  Total dry mass : %.0f g  (flight %.0f g)\n', PS.totals.dry_mass_g, PS.totals.flight_mass_g);
fprintf('  Aggregate CG   : [%+.1f, %+.1f, %+.1f] mm\n', PS.totals.cg_m*1000);
fprintf('  FAA Part 101   : %s (areal density %.3f psi)\n', ...
    ternary(PS.faa.compliant,'COMPLIANT','VIOLATION'), PS.faa.areal_density_psi);
save(fullfile(cfg.paths.data_proc,'payload_systems.mat'),'PS');

% --- data-driven wind profile
fprintf('\n=== WIND PROFILE (data-derived) ===\n');
wind = build_wind_profile(D, cfg);
fprintf('  Profile bins   : %d (%.0f m to %.0f m)\n', numel(wind.h_m), min(wind.h_m), max(wind.h_m));

% --- 3D physics simulation
sim3d = struct();
if ~opts.NoSim
    fprintf('\n=== 3D ASCENT (RK4 with wind) ===\n');
    sim3d.ascent = simulate_3d_ascent(cfg, wind);
    fprintf('  Sim apex     : %.0f m,  drift %.2f km\n', ...
        sim3d.ascent.Properties.UserData.apex_m, sim3d.ascent.Properties.UserData.drift_km);

    fprintf('\n=== 3D DESCENT (parachute opening shock) ===\n');
    A3 = sim3d.ascent;
    sim3d.descent = simulate_3d_descent(cfg, wind, ...
        [A3.x_E(end), A3.x_N(end), A3.x_U(end)], ...
        [A3.v_E(end), A3.v_N(end), A3.v_U(end)]);
    sim3d.descent.Properties.UserData.t0 = A3.Properties.UserData.apex_t_s;
    fprintf('  Peak shock   : %.1f N (%.1f g),  impact %.2f m/s\n', ...
        sim3d.descent.Properties.UserData.peak_shock_N, ...
        sim3d.descent.Properties.UserData.peak_g, ...
        sim3d.descent.Properties.UserData.impact_v_ms);
    sim.ascent3d  = sim3d.ascent;
    sim.descent3d = sim3d.descent;
end

% --- link budget
fprintf('\n=== APRS LINK BUDGET ===\n');
link = link_budget_aprs(cfg, D.trajectory);
fprintf('  Worst margin   : %.1f dB,  mean SNR %.1f dB\n', ...
    min(link.link_margin_dB), mean(link.snr_dB,'omitnan'));

% --- IGRF ambient field at apex (for mag sanity check)
[apex_m_v, kapex] = max(D.trajectory.alt_m);
B_apex = igrf13_field(D.trajectory.lat(kapex), D.trajectory.lon(kapex), apex_m_v, 2026.24);
fprintf('  IGRF |B| @apex : %.0f nT,  inc %.1f deg,  dec %.1f deg\n', ...
    B_apex.B_total, B_apex.inc_deg, B_apex.dec_deg);

% --- attitude fusion
fprintf('\n=== ATTITUDE FUSION (Madgwick) ===\n');
arduino_fused = sensor_fusion_attitude(D.arduino, 0.5);
if ~isempty(arduino_fused)
    save(fullfile(cfg.paths.data_proc,'attitude_fused.mat'),'arduino_fused');
    fprintf('  Yaw range      : [%.0f, %.0f] deg\n', min(arduino_fused.yaw_deg), max(arduino_fused.yaw_deg));
end

% --- monte carlo
MC = struct('N',0);
if ~opts.NoSim && ~opts.Quick
    fprintf('\n=== MONTE CARLO DISPERSION ===\n');
    MC = monte_carlo_dispersion(cfg, wind, 100);
    fprintf('  CEP50 = %.2f km, CEP95 = %.2f km\n', MC.cep50_km, MC.cep95_km);
end

% --- validation
fprintf('\n=== VALIDATION SUITE ===\n');
val = validation_suite(D, sim, cfg);
if isfield(val,'summary_table'), disp(val.summary_table); end

% --- flight events & dynamics
fprintf('\n=== FLIGHT EVENTS & DYNAMICS ===\n');
events = detect_flight_events(D, cfg);
if isfield(events,'summary_table'), disp(events.summary_table); end
FD = analyze_flight_dynamics(D, cfg);
save(fullfile(cfg.paths.data_proc,'flight_dynamics.mat'),'FD','events');

% --- viz
fprintf('\n=== FIGURES ===\n');
viz_trajectory(D, cfg);
viz_atmosphere(D, cfg);
viz_science(D, cfg);
viz_imu(D, cfg);
viz_3d_globe(D, cfg);
viz_wind_profile(wind, cfg);
viz_link_budget(link, cfg);
if ~opts.NoSim, viz_simulation(D, cfg, sim); end
if ~isempty(thermal), viz_thermal_power(thermal, power, cfg); end
if MC.N>0, viz_dispersion(MC, cfg); end
viz_payload(PS, cfg);
viz_phase_timeline(D, events, FD, cfg);
viz_aerodynamics(FD, cfg);
try, viz_payload_photos(PS, cfg);    catch ME, warning('payload photos: %s', ME.message); end
try, viz_payload_3d_render(PS, cfg); catch ME, warning('payload 3D: %s', ME.message); end
try, viz_website_overlay(D, cfg);    catch ME, warning('website overlay: %s', ME.message); end
try, viz_gforce_burst(D, cfg);       catch ME, warning('gforce burst: %s', ME.message); end

% --- payload engineering layer (Personfu / Phoenix-1 carbon-fiber body) -----
fprintf('\n=== PAYLOAD ENGINEERING (Phoenix-1) ===\n');
PE = payload_engineering();
fprintf('  m=%.3f kg | CG=[%.3f %.3f %.3f] m | I_diag=[%.4f %.4f %.4f] kg m^2\n', ...
    PE.totals.mass_kg, PE.totals.CG_m, PE.totals.I_diag_kgm2);
save(fullfile(cfg.paths.data_proc,'payload_engineering.mat'),'PE');
try, viz_payload_cad(PE, cfg);              catch ME, warning('payload CAD: %s', ME.message); end
try, viz_payload_structural(PE, cfg);       catch ME, warning('payload struct: %s', ME.message); end
try, viz_payload_thermal_skin(PE, cfg, D);  catch ME, warning('payload thermal: %s', ME.message); end
try, viz_payload_aero(PE, cfg);             catch ME, warning('payload aero: %s', ME.message); end
try, viz_payload_power(PE, cfg);            catch ME, warning('payload power: %s', ME.message); end
try, viz_payload_link_budget(PE, D, cfg);   catch ME, warning('payload link: %s', ME.message); end
try, viz_payload_sensors(PE, D, cfg);       catch ME, warning('payload sensors: %s', ME.message); end
try, export_payload_bom(PE, cfg);           catch ME, warning('payload bom: %s', ME.message); end

% --- exports (KML / GPX)
fprintf('\n=== EXPORTS ===\n');
try, export_kml(D, track, cfg); catch ME, warning('KML export: %s', ME.message); end
try, export_gpx(D, cfg);        catch ME, warning('GPX export: %s', ME.message); end

% --- report
fprintf('\n=== REPORTS ===\n');
write_report(cfg, D, track, sim, thermal, power);
write_mission_report(D, sim, MC, link, val, cfg);
try, write_html_dashboard(D, sim, MC, link, val, events, FD, PS, cfg);
catch ME, warning('HTML dashboard: %s', ME.message); end

results = struct('cfg',cfg,'D',D,'track',track,'sim',sim, ...
                 'thermal',thermal,'power',power, ...
                 'PS',PS,'wind',wind,'link',link,'B_apex',B_apex, ...
                 'MC',MC,'val',val,'arduino_fused',arduino_fused, ...
                 'events',events,'FD',FD,'PE',PE);
fprintf('\n[ASCEND-S26] Pipeline complete.\n');
end

function out = ternary(cond, a, b)
if cond, out = a; else, out = b; end
end

% =====================================================================
function banner()
fprintf([
'+---------------------------------------------------------------+\n', ...
'|   PHOENIX COLLEGE  -  NASA ASCEND  -  SPRING 2026              |\n', ...
'|   Balloon 2  /  KA7NSR-15  /  2026-03-28 16:38:54 UTC          |\n', ...
'|   Master MATLAB simulation pipeline by Personfu                 |\n', ...
'+---------------------------------------------------------------+\n']);
end

% =====================================================================
function write_report(cfg, D, track, sim, thermal, power)
fp = fullfile(cfg.paths.reports,'ASCEND_S26_summary.txt');
fid = fopen(fp,'w');
oc = onCleanup(@() fclose(fid));
T = D.trajectory; W = D.wind; G = D.geiger; M = D.multi; A = D.arduino;

p = @(varargin) fprintf(fid, varargin{:});
p('===========================================================\n');
p(' PHOENIX COLLEGE - NASA ASCEND - SPRING 2026\n');
p(' Balloon 2  /  KA7NSR-15\n');
p(' Launch UTC : %s\n', datestr(cfg.mission.launch_time_utc,'yyyy-mm-dd HH:MM:SS'));
p(' Launch Lat : %.5f N\n', cfg.mission.launch_lat);
p(' Launch Lon : %.5f E\n', cfg.mission.launch_lon);
p(' Launch Alt : %.1f m  (%.0f ft) MSL\n', cfg.mission.launch_alt_m, cfg.mission.launch_alt_m/0.3048);
p('===========================================================\n\n');

p('-- TRAJECTORY (APRS-derived, %d fixes) --\n', height(T));
[apex,iA] = max(T.alt_m);
p(' Apex altitude : %.1f m  (%.0f ft)  at T+%.1f min\n', apex, apex/0.3048, T.t_s(iA)/60);
p(' Burst recorded: %.1f m  (%.0f ft)\n', cfg.mission.burst_alt_m, cfg.mission.burst_alt_ft);
p(' Apex range    : %.2f km from launch (bearing %.0f deg)\n', track.range_km(iA), track.bearing_deg(iA));
p(' Landing range : %.2f km from launch (bearing %.0f deg)\n', track.range_km(end), track.bearing_deg(end));
p(' Max ground rng: %.2f km\n', max(track.range_km));
p(' Peak ascent v : %.1f mph\n', max(T.vz_mph,[],'omitnan'));
p(' Peak descent v: %.1f mph\n', min(T.vz_mph,[],'omitnan'));
p(' Impact speed  : %.1f mph\n', cfg.mission.impact_mph);
p(' Flight dur    : %.1f min\n\n', max(T.t_s)/60);

p('-- WINDSPEED (Vincenty inverse, %d fixes) --\n', height(W));
p(' Max lateral wind : %.2f mph\n', max(W.vlat_mph,[],'omitnan'));
p(' Max ascent v_z   : %.2f mph\n', max(W.vz_mph,[],'omitnan'));
p(' Max descent v_z  : %.2f mph\n', min(W.vz_mph,[],'omitnan'));
p(' Max net speed    : %.2f mph\n\n', max(W.vnet_mph,[],'omitnan'));

p('-- COSMIC RAYS (GMC-320+, %d samples) --\n', height(G));
p(' Mean dose rate   : %.3f uSv/h\n', mean(G.dose_uSvph,'omitnan'));
p(' Peak dose rate   : %.3f uSv/h\n', max(G.dose_uSvph,[],'omitnan'));
p(' Mean CPM         : %.0f\n', mean(G.cpm,'omitnan'));
p(' Peak CPM         : %.0f\n', max(G.cpm,[],'omitnan'));
p(' Modeled Pfotzer max altitude : %.1f km\n', cfg.science.pfotzer_alt_m/1000);
p(' Modeled Pfotzer peak dose    : %.2f uSv/h\n\n', cfg.science.pfotzer_peak_uSvph);

p('-- MULTISENSOR (PMS5003 + SCD30, %d samples) --\n', height(M));
p(' Mean PM2.5  : %.1f ug/m^3 | peak %.1f\n', mean(M.pm25,'omitnan'), max(M.pm25,[],'omitnan'));
p(' Mean PM10   : %.1f ug/m^3 | peak %.1f\n', mean(M.pm100,'omitnan'), max(M.pm100,[],'omitnan'));
p(' Mean CO2    : %.0f ppm | peak %.0f\n', mean(M.co2_ppm,'omitnan'), max(M.co2_ppm,[],'omitnan'));
p(' Mean T inside box : %.1f C\n', mean(M.temp_C,'omitnan'));
p(' Mean RH           : %.1f %%\n\n', mean(M.rh_pct,'omitnan'));

p('-- ARDUINO STACK (UV triads + BMP390 + ICM-20948 + LIS3MDL, %d samples) --\n', height(A));
p(' Mean UVA : %.3f mW/cm^2 | peak %.3f\n', mean(A.UVA_mWcm2,'omitnan'), max(A.UVA_mWcm2,[],'omitnan'));
p(' Mean UVB : %.3f mW/cm^2 | peak %.3f\n', mean(A.UVB_mWcm2,'omitnan'), max(A.UVB_mWcm2,[],'omitnan'));
p(' Mean UVC : %.3f mW/cm^2 | peak %.3f\n', mean(A.UVC_mWcm2,'omitnan'), max(A.UVC_mWcm2,[],'omitnan'));
p(' BMP390 alt range : [%.0f , %.0f] m\n', min(A.alt_baro_m), max(A.alt_baro_m));
p(' Peak |a|         : %.2f g\n\n', max(A.accel_total_g,[],'omitnan'));

if ~isempty(sim) && isfield(sim,'ascent')
    p('-- SIMULATION --\n');
    p(' Sim apex alt   : %.0f m  (%.0f ft)\n', sim.ascent.Properties.UserData.apex_m, ...
        sim.ascent.Properties.UserData.apex_m/0.3048);
    p(' Sim apex t     : %.0f s (%.1f min)\n', sim.ascent.Properties.UserData.apex_t_s, ...
        sim.ascent.Properties.UserData.apex_t_s/60);
    p(' Sim peak descent : %.1f mph\n', sim.descent.Properties.UserData.peak_v_mph);
    p(' Sim impact speed : %.1f mph\n\n', sim.descent.Properties.UserData.impact_v_mph);
end

if ~isempty(thermal)
    p('-- THERMAL & POWER --\n');
    p(' Box T range  : [%.1f , %.1f] C\n', min(thermal.T_box_C), max(thermal.T_box_C));
    p(' Heater duty  : %.1f %%\n', 100*mean(thermal.heater_on));
    p(' Energy used  : %.2f Wh of %.2f Wh\n', max(power.energy_used_Wh), cfg.power.pack_energy_Wh);
    p(' DoD          : %.1f %%\n\n', max(power.DoD_pct));
end

p('============= END OF REPORT =============\n');
fprintf('  written -> %s\n', fp);
end
