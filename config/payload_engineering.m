function PE = payload_engineering()
%PAYLOAD_ENGINEERING  Authoritative engineering description of the
%   Phoenix College ASCEND Spring 2026 flight payload.
%
%   Designed by Personfu - mission-grade material, structural,
%   thermal, aerodynamic, and electrical specification of the
%   actual flown article (carbon-fiber wrapped 3-D printed
%   cylindrical pressure-vented enclosure, ~1.36 kg / 3 lb).
%
%   This is the SINGLE SOURCE OF TRUTH consumed by every payload
%   engineering visualization, FEA-lite calculation and BOM export.

PE = struct();

% =================================================================
% 0.  Top-level identity
% =================================================================
PE.name        = 'PCC-ASCEND S26 Payload "Phoenix-1"';
PE.designer    = 'Personfu';
PE.team        = 'Phoenix College NASA ASCEND - Spring 2026';
PE.target_mass_kg = 1.360;        % FAA Part 101 limit per payload < 6 lb
PE.actual_mass_kg = 1.358;        % weighed; see BOM below
PE.envelope_dim_mm = [180 180 360]; % bounding box D x D x H (cylinder + cap)
PE.color       = struct('body','#C8102E','cap','#1A1A1A','vent','#A50021');

% =================================================================
% 1.  Geometry  (cylindrical pressure-vented architecture)
% =================================================================
G = struct();
G.body_OD_mm   = 165;             % outer diameter of CF-wrapped body
G.body_ID_mm   = 156;             % inner clear bay
G.body_H_mm    = 240;             % cylindrical body height
G.cap_H_mm     = 70;              % top truss cap (printed lattice)
G.dome_H_mm    = 60;              % bottom optical/vent dome
G.wall_t_mm    = 2.4;             % printed nominal wall
G.cf_wrap_t_mm = 0.25;            % 1 ply 3K twill ~0.22-0.28 mm
G.skin_t_mm    = G.wall_t_mm + G.cf_wrap_t_mm;
G.band_w_mm    = 18;              % 2 retention bands at H/3 and 2H/3
G.band_t_mm    = 1.6;             % printed band thickness
G.bridle_holes = 4;               % 4-point bridle through cap truss
G.vent_area_mm2= 380;             % bottom red vent port (sized for ?P relief)
G.optical_port = struct('OD_mm',55,'material','PMMA','transmission',0.92);
PE.geometry = G;

% =================================================================
% 2.  Materials  (printed shell + carbon wrap + epoxy)
% =================================================================
M = struct();
M.printed = struct( ...
    'name','PETG-CF (15% chopped carbon)', ...
    'rho_kg_m3',1310, ...
    'E_GPa',3.6, ...
    'sigma_y_MPa',55, ...
    'sigma_u_MPa',74, ...
    'CTE_1perK',6e-5, ...
    'k_W_mK',0.27, ...
    'cp_J_kgK',1100, ...
    'Tg_C',82);
M.cf_wrap = struct( ...
    'name','3K 2x2 twill carbon prepreg, 1 ply, ~0.25 mm', ...
    'rho_kg_m3',1600, ...
    'E1_GPa',70, ...     % woven in-plane
    'E2_GPa',70, ...
    'G12_GPa',5, ...
    'nu12',0.05, ...
    'sigma_t_MPa',900, ...
    'sigma_c_MPa',570, ...
    'k_W_mK',5.0, ...    % through plane ~0.7, in-plane ~5
    'cp_J_kgK',1050);
M.epoxy = struct( ...
    'name','laminating epoxy 2:1', ...
    'rho_kg_m3',1150,'k_W_mK',0.20,'cp_J_kgK',1200);
M.paint = struct( ...
    'name','flight red enamel', ...
    'absorptivity_solar',0.92,'emissivity_LWIR',0.88, ...
    'mass_g',12);
M.foam_liner = struct( ...
    'name','XPS interior thermal liner 8 mm', ...
    'rho_kg_m3',32,'k_W_mK',0.030,'cp_J_kgK',1500,'t_mm',8);
M.bus_PMMA = struct( ...
    'name','PMMA optical port', ...
    'rho_kg_m3',1180,'k_W_mK',0.19,'cp_J_kgK',1450, ...
    'absorptivity_solar',0.05,'transmission_uv',0.85);
PE.materials = M;

% =================================================================
% 3.  Mass / CG / Inertia (lumped subsystem inventory)
% =================================================================
% Each entry: name, mass_g, position [x y z] from base center (m),
%              size [a b c] (m) treated as box for I_local.
S = {
    'CF/PETG shell',         410, [ 0.000  0.000 0.150], [0.165 0.165 0.300];
    'XPS thermal liner',      55, [ 0.000  0.000 0.140], [0.150 0.150 0.230];
    'Top truss cap',         120, [ 0.000  0.000 0.305], [0.180 0.180 0.070];
    'APRS tracker (LightAPRS)', 38, [ 0.000  0.000 0.310], [0.080 0.060 0.020];
    '1/4? whip antenna',      18, [ 0.000  0.000 0.420], [0.005 0.005 0.500];
    'Arduino Mega 2560',      62, [ 0.045  0.000 0.210], [0.110 0.055 0.020];
    'BMP390 + 4xUV triad',    24, [-0.045  0.020 0.215], [0.080 0.040 0.015];
    'LSM6DSO + LIS3MDL IMU',  10, [ 0.000  0.040 0.218], [0.030 0.025 0.010];
    'GMC-320+ Geiger',       105, [-0.040 -0.020 0.180], [0.110 0.060 0.030];
    'SCD41 CO2',              18, [ 0.040  0.020 0.180], [0.040 0.025 0.020];
    'PMS5003 PM',             42, [ 0.000 -0.040 0.170], [0.050 0.038 0.021];
    'SHT41 T/RH',              5, [-0.040  0.040 0.165], [0.020 0.018 0.008];
    '8x AA Energizer L91',   210, [ 0.000  0.000 0.090], [0.090 0.060 0.060];
    'BMS / wiring harness',   72, [ 0.000  0.000 0.110], [0.080 0.080 0.040];
    'Micro SD logger',         8, [ 0.030 -0.030 0.190], [0.020 0.020 0.005];
    'Optical PMMA port',      26, [ 0.000  0.000 0.030], [0.055 0.055 0.010];
    'Bottom vent + dome',     65, [ 0.000  0.000 0.025], [0.140 0.140 0.060];
    'CF retention bands x2',  40, [ 0.000  0.000 0.150], [0.170 0.170 0.005];
    'Bridle harness (kevlar)',30, [ 0.000  0.000 0.350], [0.010 0.010 0.300];
    'Hardware (M3/M4 ti)',    30, [ 0.000  0.000 0.180], [0.020 0.020 0.020];
};
PE.mass_table = cell2table(S, 'VariableNames', ...
    {'item','mass_g','pos_xyz_m','dims_xyz_m'});

% aggregate
m = cell2mat(PE.mass_table.mass_g)/1000;
p = cell2mat(PE.mass_table.pos_xyz_m);
d = cell2mat(PE.mass_table.dims_xyz_m);
M_tot = sum(m);
CG    = (m.' * p) / M_tot;
% inertia about CG (parallel-axis theorem, box approximation)
I = zeros(3,3);
for k = 1:numel(m)
    a=d(k,1); b=d(k,2); c=d(k,3);
    Ilocal = (m(k)/12) * diag([b^2+c^2, a^2+c^2, a^2+b^2]);
    r = (p(k,:)-CG).';
    Ipa = m(k) * (dot(r,r)*eye(3) - r*r.');
    I  = I + Ilocal + Ipa;
end
PE.totals = struct('mass_kg',M_tot,'CG_m',CG,'I_kgm2',I, ...
                   'I_diag_kgm2',diag(I).');

% =================================================================
% 4.  Structural margins (load cases for ASCEND HAB ops)
% =================================================================
% Worst case loads:
%   - Suspension at lift-off, balloon bobbing             (1.5 g axial)
%   - Burst impulse / opening shock                        (6.5 g axial)
%   - Free-fall tumble before parachute fill               (rotation)
%   - Landing impact 8 m/s on hard ground                  (~12 g)
PE.loads = struct( ...
    'launch_g',1.5,'burst_g',6.5,'shock_g',12.0, ...
    'truth_max_g',6.211, ...
    'A_susp_mm2', 4*pi*(2.5)^2, ...                     % 4 x 5 mm bridle pads
    'F_burst_N',  M_tot*9.80665*6.5, ...
    'F_shock_N',  M_tot*9.80665*12.0);
PE.loads.sigma_susp_MPa = (PE.loads.F_shock_N/PE.loads.A_susp_mm2)*1.0;  % MPa

% Axial column buckling check (Euler) of the body acting as a thin shell
%   P_cr = pi^2 * E * I_shell / (K*L)^2,  K=0.7 fixed-pinned
E = PE.materials.cf_wrap.E1_GPa*1e9;
t = PE.geometry.skin_t_mm/1000;
R = PE.geometry.body_OD_mm/2000;
I_shell = pi*R^3*t;                                  % thin-shell second moment
L = PE.geometry.body_H_mm/1000; K = 0.7;
PE.loads.P_buckle_N = pi^2*E*I_shell / (K*L)^2;
PE.loads.MS_buckle  = PE.loads.P_buckle_N / PE.loads.F_shock_N - 1;

% Hoop stress from internal pressure differential (vented)
% Vented enclosure should hold dP <= 5 kPa under full expansion
PE.loads.dP_max_Pa  = 5000;
PE.loads.sigma_hoop_MPa = (PE.loads.dP_max_Pa * R / t)/1e6;
PE.loads.MS_hoop = PE.materials.cf_wrap.sigma_t_MPa*0.5 / PE.loads.sigma_hoop_MPa - 1;

% =================================================================
% 5.  Thermal interface map (lumped + radiative)
% =================================================================
T = struct();
T.A_outer_m2 = pi*(PE.geometry.body_OD_mm/1000)*(PE.geometry.body_H_mm/1000) + ...
                pi*(PE.geometry.body_OD_mm/2000)^2*2;
T.alpha_solar = 0.92;
T.eps_LWIR    = 0.88;
T.k_eff_wall  = 1/((PE.geometry.wall_t_mm/1000)/PE.materials.printed.k_W_mK + ...
                   (PE.geometry.cf_wrap_t_mm/1000)/PE.materials.cf_wrap.k_W_mK + ...
                   (PE.materials.foam_liner.t_mm/1000)/PE.materials.foam_liner.k_W_mK);
T.UA_wall_W_K = T.k_eff_wall * T.A_outer_m2;
T.cp_eff_J_K  = M_tot * 900;        % bulk Cp ~ 900 J/kg/K composite
T.tau_thermal_s = T.cp_eff_J_K / max(T.UA_wall_W_K,1e-3);
T.Q_internal_W  = 2.4;              % MCU+radio+sensors avg dissipation
PE.thermal = T;

% =================================================================
% 6.  Aerodynamics  (cylinder in axial / cross flow)
% =================================================================
A = struct();
A.D_m   = PE.geometry.body_OD_mm/1000;
A.L_m   = (PE.geometry.body_H_mm + PE.geometry.cap_H_mm + PE.geometry.dome_H_mm)/1000;
A.A_front_m2 = pi*(A.D_m/2)^2;
A.A_side_m2  = A.D_m * A.L_m;
A.Cd_axial   = 0.82;       % blunt cylinder along axis
A.Cd_cross   = 1.10;       % side-on cylinder L/D ~2
A.Cd_descent = 0.85;       % under canopy, payload streamwise
A.Sref_m2    = A.A_front_m2;
PE.aero = A;

% =================================================================
% 7.  Electrical bus (single-line summary)
% =================================================================
E = struct();
E.bus_V        = 12.0;             % 8x AA L91 nominal 12V
E.bus_capacity_Wh = 8*1.5*3.0;     % 8 cells * 1.5V * 3 Ah = 36 Wh
E.regulators   = {'5V buck (sensors)','3V3 LDO (BMP/IMU/SD)','9V boost (Geiger)'};
E.peak_W       = 4.6;              % radio TX + heaters peak
E.avg_W        = 2.4;
E.flight_h     = 1.6;              % nominal recovery margin
E.energy_used_Wh = E.avg_W * E.flight_h;
E.depth_of_discharge = E.energy_used_Wh / E.bus_capacity_Wh;
PE.electrical = E;

% =================================================================
% 8.  Telemetry / comms
% =================================================================
C = struct();
C.aprs.callsign = 'KA7NSR-15';
C.aprs.freq_MHz = 144.39;
C.aprs.tx_W     = 0.5;
C.aprs.gain_dBi = 2.15;             % 1/4 lambda whip
C.aprs.beacon_s = 60;
C.aprs.path     = 'WIDE2-1';
C.gnd.station   = 'Phoenix College ground';
C.gnd.gain_dBi  = 6.0;
C.gnd.NF_dB     = 1.5;
PE.comms = C;

% =================================================================
% 9.  Compliance
% =================================================================
PE.compliance.faa_part_101 = struct( ...
    'mass_under_6lb', M_tot*2.2046 < 6, ...
    'package_density_under_3oz_in2', true, ...
    'rope_breaking_50lbf', true);
end
