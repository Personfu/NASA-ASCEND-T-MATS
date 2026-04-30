function R = simulate_3d_ascent(cfg, wind)
%SIMULATE_3D_ASCENT  3-DOF translational ascent (east/north/up) with wind.
%
%   R = SIMULATE_3D_ASCENT(cfg, wind) integrates the balloon's center of
%   mass in a local ENU frame at the launch site:
%
%       m d^2r/dt^2 = F_buoy + F_grav + F_drag(v_rel) + F_apparent_mass
%
%   - Buoyancy acts +U
%   - Gravity acts -U with WGS-84 latitude correction
%   - Drag is computed in v_rel = v_balloon - v_wind (3-vector); ENU wind
%     U(h),V(h) supplied by wind.profile, vertical wind = 0
%   - Apparent mass for a sphere ascending in air = 0.5 rho V_balloon
%     (added to translational inertia in the vertical direction)
%
%   Output: timetable with t, x_E, x_N, x_U, v_E, v_N, v_U, |v|,
%           lat, lon, alt_m, p, T, rho, V_b, D_b, Mach, Re

g0 = cfg.atm.g0;
M  = cfg.balloon.gas_mol_kgmol;
Mair = cfg.atm.M_air_kgmol;
Ru = cfg.atm.Ru;
V0 = cfg.balloon.fill_volume_m3;
[T0, P0] = atm_us1976(cfg.mission.launch_alt_m);
n_gas = P0*V0/(Ru*T0);
m_load = cfg.payload.total_mass_kg + cfg.balloon.mass_kg;

% Latitude-dependent gravity (Somigliana)
phi = deg2rad(cfg.mission.launch_lat);
g_lat = 9.7803267715*(1 + 0.001931851353*sin(phi)^2)/sqrt(1 - 0.0066943800229*sin(phi)^2);

dt = 0.5;
tmax = 4.5*3600;
N = ceil(tmax/dt);
[t, X] = deal(zeros(N,3));     % position E,N,U
V = zeros(N,3);                % velocity
[Db,Vb_,Tair,Pair,rho_a,Mach,Re] = deal(zeros(N,1));
X(1,:) = [0,0,cfg.mission.launch_alt_m];

for k = 1:N-1
    [k1x,k1v] = deriv(X(k,:),         V(k,:));
    [k2x,k2v] = deriv(X(k,:)+dt/2*k1x,V(k,:)+dt/2*k1v);
    [k3x,k3v] = deriv(X(k,:)+dt/2*k2x,V(k,:)+dt/2*k2v);
    [k4x,k4v] = deriv(X(k,:)+dt*k3x,  V(k,:)+dt*k3v);
    X(k+1,:) = X(k,:) + dt/6*(k1x+2*k2x+2*k3x+k4x);
    V(k+1,:) = V(k,:) + dt/6*(k1v+2*k2v+2*k3v+k4v);
    t(k+1)   = t(k) + dt;

    h = X(k+1,3);
    [Tk,Pk,rk,ak,muk] = atm_us1976(h);
    Tair(k+1)=Tk; Pair(k+1)=Pk; rho_a(k+1)=rk;
    Vbk = (n_gas*Ru*Tk)/Pk;
    Dbk = (6*Vbk/pi)^(1/3);
    Vb_(k+1)=Vbk; Db(k+1)=Dbk;
    Mach(k+1) = norm(V(k+1,:))/ak;
    Re(k+1)   = rk*norm(V(k+1,:))*Dbk/max(muk,1e-9);

    if Dbk >= cfg.balloon.burst_diam_m || h >= cfg.mission.burst_alt_m
        N = k+1; break;
    end
end
t=t(1:N); X=X(1:N,:); V=V(1:N,:);
Tair=Tair(1:N); Pair=Pair(1:N); rho_a=rho_a(1:N);
Vb_=Vb_(1:N); Db=Db(1:N); Mach=Mach(1:N); Re=Re(1:N);
[Tair(1),Pair(1),rho_a(1)] = atm_us1976(X(1,3));
Vb_(1)=V0; Db(1)=(6*V0/pi)^(1/3);

% Convert ENU to lat/lon path
lat = zeros(N,1); lon = zeros(N,1);
for i = 1:N
    [lat(i), lon(i)] = enu_to_lla(X(i,1), X(i,2), cfg.mission.launch_lat, cfg.mission.launch_lon);
end

R = timetable(seconds(t(:)), X(:,1), X(:,2), X(:,3), ...
    V(:,1), V(:,2), V(:,3), sqrt(sum(V.^2,2)), ...
    lat, lon, Tair, Pair, rho_a, Vb_, Db, Mach, Re, ...
    'VariableNames',{'x_E','x_N','x_U','v_E','v_N','v_U','speed','lat','lon', ...
                     'T_K','P_Pa','rho','Vb_m3','Db_m','Mach','Re'});
R.Properties.DimensionNames{1}='t';
R.Properties.UserData.apex_m   = X(end,3);
R.Properties.UserData.apex_t_s = t(end);
R.Properties.UserData.drift_km = norm(X(end,1:2))/1000;

% =====================================================================
    function [dx,dv] = deriv(x_, v_)
        h_ = x_(3);
        [Tl,Pl,rhol,~,~] = atm_us1976(h_);
        Vbl = (n_gas*Ru*Tl)/Pl;
        Dbl = (6*Vbl/pi)^(1/3);
        rhoHe = Pl*M/(Ru*Tl);
        Fb = (rhol - rhoHe)*Vbl*g_lat;
        Ab = pi*(Dbl/2)^2;

        % Wind at this altitude
        [u_w, v_w] = wind.profile(h_);
        v_rel = v_ - [u_w, v_w, 0];

        Cd_b = cfg.balloon.cd;
        Cd_p = cfg.payload.cd_box;
        Ap   = cfg.payload.frontal_area_m2;
        F_drag_b = -0.5*rhol*Cd_b*Ab*norm(v_rel)*v_rel;
        F_drag_p = -0.5*rhol*Cd_p*Ap*norm(v_rel)*v_rel;

        % Apparent (virtual) mass for sphere
        m_app = 0.5*rhol*Vbl;
        m_eff = m_load + n_gas*M + m_app;

        F = F_drag_b + F_drag_p + [0, 0, Fb - (m_load+n_gas*M)*g_lat];
        dv = F/m_eff;
        dx = v_;
    end
end

function [lat, lon] = enu_to_lla(E, N, lat0, lon0)
% Small-area flat-earth: converts ENU offsets (m) to lat/lon
Re = 6371008.8;
lat = lat0 + rad2deg(N/Re);
lon = lon0 + rad2deg(E/(Re*cosd(lat0)));
end
