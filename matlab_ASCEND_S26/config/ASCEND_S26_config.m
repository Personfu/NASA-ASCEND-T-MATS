function cfg = ASCEND_S26_config()
%ASCEND_S26_CONFIG  Mission configuration for Phoenix College NASA ASCEND Spring 2026.
%
%   cfg = ASCEND_S26_CONFIG() returns a struct with every constant, path,
%   payload mass property, balloon spec and environmental parameter used
%   across the simulation suite. Editing this single file rewires the
%   entire pipeline.
%
%   Phoenix College NASA ASCEND  -  Spring 2026 Balloon 2
%   Launch:  2026-03-28  16:38:54 UTC
%   Site:    32.87533 N, -112.0495 W   (Maricopa County, AZ)
%   Burst:   82,496.995 ft (25,145 m)  -  T+5h25m after release
%   Max descent: 63.56 mph    Impact: ~15.1 mph
%
%   Authoring:  Personfu / NASA ASCEND PhxCC

% ------------------------------------------------------------------ paths
here = fileparts(mfilename('fullpath'));
cfg.paths.root      = fileparts(here);
cfg.paths.config    = here;
cfg.paths.data_raw  = fullfile(cfg.paths.root, 'data', 'raw');
cfg.paths.data_proc = fullfile(cfg.paths.root, 'data', 'processed');
cfg.paths.figures   = fullfile(cfg.paths.root, 'figures');
cfg.paths.reports   = fullfile(cfg.paths.root, 'reports');
cfg.paths.models    = fullfile(cfg.paths.root, 'src', 'models');
for f = ["data_proc","figures","reports"]
    if ~exist(cfg.paths.(f), 'dir'); mkdir(cfg.paths.(f)); end
end

% ------------------------------------------------------------------ mission
cfg.mission.name           = 'Phoenix College NASA ASCEND - Spring 2026';
cfg.mission.balloon_id     = 'Balloon 2';
cfg.mission.aprs_callsign  = 'KA7NSR-15';
cfg.mission.launch_time_utc= datetime(2026,3,28,16,38,54,'TimeZone','UTC');
cfg.mission.launch_lat     = 32.87533;        % deg N
cfg.mission.launch_lon     = -112.0495;       % deg E
cfg.mission.launch_alt_m   = 418.8;           % MSL, m
cfg.mission.burst_alt_m    = 25144.78;        % 82,496.995 ft
cfg.mission.burst_alt_ft   = 82496.995;
cfg.mission.flight_dur_s   = 5*3600 + 25*60;  % nominal flight duration
cfg.mission.impact_mph     = 15.1;
cfg.mission.peak_descent_mph = 63.56;

% ------------------------------------------------------------------ ground truth (NASA-ASCEND-Website data)
cfg.truth.landing_lat        = 33.1125;       % deg N  (recovered touchdown)
cfg.truth.landing_lon        = -111.6335;     % deg E
cfg.truth.burst_time_utc     = datetime(2026,3,28,17,39,36,'TimeZone','UTC');
cfg.truth.peak_alt_m         = 25145.4;
cfg.truth.peak_alt_ft        = 82498.0;
cfg.truth.flight_dur_min     = 89.0;
cfg.truth.gnd_dist_km        = 57.37;
cfg.truth.max_gs_kmh         = 93.0;
cfg.truth.avg_ascent_ms      = 7.33;
cfg.truth.avg_descent_ms     = -12.65;
cfg.truth.min_temp_c         = 3;             % published rounded
cfg.truth.min_pressure_pa    = 1242;
cfg.truth.max_g_load         = 6.211;
cfg.truth.max_g_alt_ft       = 68761;
cfg.truth.max_g_elapsed_s    = 3844;
cfg.truth.peak_cpm           = 524;
cfg.truth.peak_uSv_h         = 3.406;
cfg.truth.pfotzer_alt_ft     = 63300;         % Pfotzer-Regener observed
cfg.truth.peak_uv_total      = 9936.5;        % UV1+2+3+4 sum

% ------------------------------------------------------------------ assets / website artifacts
cfg.paths.assets        = fullfile(cfg.paths.root, 'assets');
cfg.paths.assets_imgs   = fullfile(cfg.paths.assets, 'images');
cfg.paths.assets_data   = fullfile(cfg.paths.assets, 'data');
cfg.files.web_payload   = fullfile(cfg.paths.assets_data, 'spring2026_payload.json');
cfg.files.web_imu       = fullfile(cfg.paths.assets_data, 'spring2026_imu_public.json');
cfg.files.web_radiation = fullfile(cfg.paths.assets_data, 'spring2026_radiation_public.json');
cfg.files.web_aprs      = fullfile(cfg.paths.assets_data, 'spring2026_aprs_track.json');
cfg.files.web_telemetry = fullfile(cfg.paths.assets_data, 'spring2026_telemetry.json');

% ------------------------------------------------------------------ raw data
R = cfg.paths.data_raw;
cfg.files.trajectory   = fullfile(R, 'parameterization_of_elapsed_time_vs_altitude_for_Balloon_2_Spring_2026_launch__Sheet1.csv');
cfg.files.windspeed    = fullfile(R, 'windspeed_vs_altitude_calculation__Sheet1.csv');
cfg.files.geiger       = fullfile(R, 'Geiger_counter_data_Spring_2026__Sheet1.csv');
cfg.files.multisensor  = fullfile(R, 'sorted_multisensor_data_Spring_2026__Sheet1.csv');
cfg.files.arduino      = fullfile(R, 'processed_arduino_data_Spring_2026__Sheet1.csv');

% ------------------------------------------------------------------ balloon
% Kaymont/Hwoyee 1500g latex sounding balloon - typical ASCEND payload class
cfg.balloon.type            = 'Latex sounding (1500 g class)';
cfg.balloon.mass_kg         = 1.500;
cfg.balloon.burst_diam_m    = 9.44;          % manufacturer burst diameter
cfg.balloon.cd              = 0.30;          % drag coefficient (sphere)
cfg.balloon.lift_gas        = 'Helium';
cfg.balloon.gas_mol_kgmol   = 4.0026e-3;     % He
cfg.balloon.fill_volume_m3  = 4.20;          % at launch
cfg.balloon.free_lift_N     = 9.81*0.85;     % nominal free lift

% ------------------------------------------------------------------ payload
cfg.payload.total_mass_kg   = 1.700;         % flight string total
cfg.payload.boxes           = struct( ...
    'tracker_g',       180,  ...   % APRS Byonics MicroTrak
    'multisensor_g',   420,  ...   % PM/CO2/T/H board
    'arduino_g',       540,  ...   % UV + BMP390 + IMU + mag
    'geiger_g',        260,  ...   % GMC-320+
    'battery_g',       240,  ...
    'parachute_g',     60);
cfg.payload.frontal_area_m2 = 0.090;         % ~30x30 cm box face
cfg.payload.cd_box          = 1.05;          % bluff cube
cfg.payload.cg_height_m     = 0.15;

% ------------------------------------------------------------------ parachute
cfg.chute.type              = 'Spherachute 36"';
cfg.chute.diameter_m        = 0.9144;
cfg.chute.cd                = 1.50;
cfg.chute.area_m2           = pi*(cfg.chute.diameter_m/2)^2;
cfg.chute.deploy_alt_m      = cfg.mission.burst_alt_m;  % at burst

% ------------------------------------------------------------------ atmosphere
cfg.atm.model           = 'US Standard 1976';
cfg.atm.g0              = 9.80665;            % m/s^2
cfg.atm.Re              = 6371.0088e3;        % mean Earth radius (m)
cfg.atm.R_air           = 287.05287;          % J/(kg K)
cfg.atm.gamma           = 1.4;
cfg.atm.M_air_kgmol     = 28.9644e-3;
cfg.atm.Ru              = 8.31446261815324;   % J/(mol K)
cfg.atm.T0              = 288.15;             % K  sea-level
cfg.atm.P0              = 101325;             % Pa
cfg.atm.rho0            = 1.225;              % kg/m^3

% Vincenty / WGS-84
cfg.wgs84.a   = 6378137.0;          % m
cfg.wgs84.f   = 1/298.257223563;
cfg.wgs84.b   = cfg.wgs84.a*(1-cfg.wgs84.f);
cfg.wgs84.e2  = cfg.wgs84.f*(2-cfg.wgs84.f);

% ------------------------------------------------------------------ thermal
cfg.thermal.box_emissivity  = 0.92;        % painted foamcore
cfg.thermal.box_absorptivity= 0.78;
cfg.thermal.box_area_m2     = 0.54;        % external area
cfg.thermal.heat_cap_J_K    = 2200;        % lumped C
cfg.thermal.solar_const_Wm2 = 1361;        % S0
cfg.thermal.albedo_earth    = 0.30;
cfg.thermal.T_deepspace_K   = 2.7;
cfg.thermal.sigma           = 5.670374419e-8;

% ------------------------------------------------------------------ power
cfg.power.battery_chem      = 'Energizer L91 Lithium AA x 8 (2S4P)';
cfg.power.cell_capacity_Ah  = 3.500;
cfg.power.pack_voltage_V    = 6.0;
cfg.power.pack_capacity_Ah  = 14.0;
cfg.power.pack_energy_Wh    = cfg.power.pack_voltage_V*cfg.power.pack_capacity_Ah;
cfg.power.loads = struct( ...
    'tracker_W',     0.85, ...
    'arduino_W',     0.55, ...
    'multisensor_W', 0.95, ...
    'geiger_W',      0.20, ...
    'heater_W',      1.20);    % thermostatic, duty-cycled
cfg.power.heater_setpoint_C = -10;

% ------------------------------------------------------------------ science
cfg.science.cosmic_ray_bg_uSvph = 0.10;        % surface background
cfg.science.pfotzer_alt_m       = 19500;       % typ Pfotzer-Regener max
cfg.science.pfotzer_peak_uSvph  = 4.20;        % typ peak at lat 33N
cfg.science.uv_solzen_deg       = 26.0;        % at solar noon equivalent
cfg.science.ozone_col_DU        = 285;         % typical AZ spring

% ------------------------------------------------------------------ plotting
cfg.plot.dpi              = 200;
cfg.plot.fontname         = 'Helvetica';
cfg.plot.colors = struct( ...
    'ascent',   [0.10 0.45 0.85], ...
    'descent',  [0.85 0.20 0.20], ...
    'burst',    [0.95 0.55 0.10], ...
    'gnd',      [0.20 0.55 0.20], ...
    'uv',       [0.55 0.10 0.65], ...
    'cosmic',   [0.85 0.10 0.45], ...
    'pm',       [0.40 0.40 0.40], ...
    'co2',      [0.10 0.65 0.55], ...
    'thermal',  [0.95 0.30 0.10]);
cfg.plot.export_formats = {'png','pdf'};

% ------------------------------------------------------------------ aliases
% Bridge legacy/new naming so every module compiles regardless of vintage.
cfg.paths.figs            = cfg.paths.figures;
cfg.viz.dpi               = cfg.plot.dpi;
cfg.viz.export_formats    = cfg.plot.export_formats;
cfg.viz.colors            = cfg.plot.colors;
cfg.parachute             = cfg.chute;          % alias for chute
cfg.parachute.diameter_m  = cfg.chute.diameter_m;
cfg.parachute.cd          = cfg.chute.cd;
cfg.parachute.area_m2     = cfg.chute.area_m2;
cfg.mission.launch_utc    = cfg.mission.launch_time_utc;

end
