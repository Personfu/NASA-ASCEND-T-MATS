function R = simulate_thermal(cfg, traj)
%SIMULATE_THERMAL  Lumped capacitance thermal model of the payload box.
%
%   R = SIMULATE_THERMAL(cfg, traj) integrates:
%
%      C dT/dt = Q_solar + Q_albedo + Q_IR_earth - Q_IR_box - Q_conv + Q_int + Q_heater
%
%   where:
%      Q_solar  = alpha * S0 * A_proj * cos(zen)        (above-horizon)
%      Q_albedo = alpha * a_E * S0 * A_proj * VF_E
%      Q_IR_E   = epsilon * sigma * T_E^4 * A_E * VF_E
%      Q_IR_box = epsilon * sigma * T_box^4 * A_box
%      Q_conv   = h(rho,v) * (T_box - T_air) * A_box     (forced/free)
%      Q_int    = sum of payload electrical power dissipated
%      Q_heater = thermostatic at setpoint
%
%   Input traj must contain alt_m and v_ms (timetable from ascent+descent).

if ~istimetable(traj)
    error('traj must be a timetable with alt_m and v_ms');
end
if ~ismember('v_ms', traj.Properties.VariableNames)
    traj.v_ms = [0; diff(traj.alt_m)./seconds(diff(traj.t))];
end

th = cfg.thermal;
sigma = th.sigma;
S0    = th.solar_const_Wm2;
alpha = th.box_absorptivity;
eps_  = th.box_emissivity;
A_box = th.box_area_m2;
A_proj= A_box/4;            % ~one face projected
C     = th.heat_cap_J_K;
T_E   = 254;                % Earth effective IR temperature (K)
VF_E  = 0.5;                % view factor at altitude

P_int = sum(structfun(@(x)x, cfg.power.loads)) - cfg.power.loads.heater_W;

n = height(traj);
T_box = zeros(n,1);
T_air = zeros(n,1);
Q     = zeros(n,5);   % [solar albedo earthIR boxIR conv]
heater = false(n,1);
T_box(1) = 298.15;     % start at 25 C inside the box

t = seconds(traj.t);
for i = 1:n
    [Tk,~,rhok,~,muk,~] = atm_us1976(traj.alt_m(i));
    T_air(i) = Tk;
    % Solar zenith angle - approximate by day-of-year & local time
    sz = solar_zenith(cfg.mission.launch_time_utc + seconds(traj.t_s(i)), ...
                      cfg.mission.launch_lat, cfg.mission.launch_lon);
    Qs  = alpha * S0 * A_proj * max(cos(deg2rad(sz)),0);
    Qa  = alpha * th.albedo_earth * S0 * A_proj * VF_E * max(cos(deg2rad(sz)),0);
    QIRe= eps_ * sigma * T_E^4 * A_box * VF_E;
    QIRb= eps_ * sigma * T_box(i)^4 * A_box;

    % Convective coefficient - mixed forced/free
    v = abs(traj.v_ms(i));
    L = 0.30;                    % characteristic length (m)
    Pr = 0.71;
    Re = rhok*v*L/max(muk,1e-9);
    Nu_f = 0.664*sqrt(max(Re,1))*Pr^(1/3);     % laminar plate forced
    k_air = 0.0263*(Tk/300)^0.84;              % approx
    h_f  = Nu_f*k_air/L;
    h_n  = 5;                                  % free convection floor
    h    = max(h_f, h_n);
    Qc   = h*(T_box(i) - Tk)*A_box;

    % Heater
    if T_box(i) - 273.15 < cfg.power.heater_setpoint_C
        Qh = cfg.power.loads.heater_W; heater(i)=true;
    else
        Qh = 0;
    end

    Qnet = Qs + Qa + QIRe - QIRb - Qc + P_int + Qh;
    if i < n
        dt = t(i+1) - t(i);
        T_box(i+1) = T_box(i) + dt*Qnet/C;
    end
    Q(i,:) = [Qs,Qa,QIRe,QIRb,Qc];
end

R = timetable(traj.t, traj.alt_m, T_box-273.15, T_air-273.15, Q(:,1), Q(:,2), Q(:,3), Q(:,4), Q(:,5), heater, ...
    'VariableNames',{'alt_m','T_box_C','T_air_C','Q_solar','Q_albedo','Q_earth_IR','Q_box_IR','Q_conv','heater_on'});
R.Properties.DimensionNames{1}='t';
end

function sz_deg = solar_zenith(dt_utc, lat, lon)
% Simple NOAA solar position - good to ~0.5 deg.
doy = day(dt_utc,'dayofyear');
gamma = 2*pi/365 * (doy - 1 + (hour(dt_utc)-12)/24);
decl = 0.006918 - 0.399912*cos(gamma) + 0.070257*sin(gamma) ...
       - 0.006758*cos(2*gamma) + 0.000907*sin(2*gamma) ...
       - 0.002697*cos(3*gamma) + 0.00148*sin(3*gamma);
eqt = 229.18*(0.000075 + 0.001868*cos(gamma) - 0.032077*sin(gamma) ...
       - 0.014615*cos(2*gamma) - 0.040849*sin(2*gamma));
tst = mod(hour(dt_utc)*60 + minute(dt_utc) + second(dt_utc)/60 + eqt + 4*lon, 1440);
ha  = deg2rad(tst/4 - 180);
phi = deg2rad(lat);
cosZ = sin(phi)*sin(decl) + cos(phi)*cos(decl)*cos(ha);
sz_deg = rad2deg(acos(max(min(cosZ,1),-1)));
end
