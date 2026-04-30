function R = simulate_ascent(cfg)
%SIMULATE_ASCENT  6-DOF-lite vertical ascent of a sounding balloon.
%
%   R = SIMULATE_ASCENT(cfg) integrates a 1-D vertical balloon ascent
%   from launch to burst using:
%
%       m_total dv/dt = F_buoy - F_grav - F_drag - F_payload_drag
%       F_buoy = (rho_air - rho_gas) * V_gas * g
%       V_gas  = V0 * (P0/P) * (T/T0)            ideal-gas expansion
%       F_drag = 1/2 rho_air Cd A v|v|
%
%   The balloon expands quasi-statically; burst is triggered when
%   diameter exceeds the manufacturer burst diameter or equivalently
%   when the integrated altitude reaches the workbook-recorded burst
%   altitude (whichever first).
%
%   Returns timetable R with t_s, alt_m, v_ms, V_balloon_m3, D_balloon_m,
%   T_K, P_Pa, rho_kgm3, a_ms2, mach, Re, F_buoy, F_drag.

% --- initial conditions
g0   = cfg.atm.g0;
M    = cfg.balloon.gas_mol_kgmol;
Mair = cfg.atm.M_air_kgmol;
Ru   = cfg.atm.Ru;

V0   = cfg.balloon.fill_volume_m3;
[T0,P0] = atm_us1976(cfg.mission.launch_alt_m);

% Helium mass from initial conditions
n_gas  = P0*V0/(Ru*T0);                  % mol
m_gas  = n_gas * M;                      % kg
m_load = cfg.payload.total_mass_kg + cfg.balloon.mass_kg;
m_tot  = m_load + m_gas;

% Burst diameter check
Dburst = cfg.balloon.burst_diam_m;

% --- integration grid (RK4)
dt = 0.5;                          % s
tmax = 4.5*3600;                   % cap
N = ceil(tmax/dt);
[t,h,v,Vb,Db,Tair,Pair,rho,Fb,Fd,Mach,ReN] = deal(zeros(N,1));
h(1) = cfg.mission.launch_alt_m;
v(1) = 0;
t(1) = 0;

for k = 1:N-1
    [k1h,k1v] = deriv(t(k),       h(k),         v(k));
    [k2h,k2v] = deriv(t(k)+dt/2,  h(k)+dt/2*k1h,v(k)+dt/2*k1v);
    [k3h,k3v] = deriv(t(k)+dt/2,  h(k)+dt/2*k2h,v(k)+dt/2*k2v);
    [k4h,k4v] = deriv(t(k)+dt,    h(k)+dt*k3h,  v(k)+dt*k3v);
    h(k+1) = h(k) + dt/6*(k1h + 2*k2h + 2*k3h + k4h);
    v(k+1) = v(k) + dt/6*(k1v + 2*k2v + 2*k3v + k4v);
    t(k+1) = t(k) + dt;

    [Tk,Pk,rhok,ak,muk] = atm_us1976(h(k+1));
    Vbk = (n_gas*Ru*Tk)/Pk;
    Dbk = (6*Vbk/pi)^(1/3);
    Vb(k+1)=Vbk; Db(k+1)=Dbk; Tair(k+1)=Tk; Pair(k+1)=Pk; rho(k+1)=rhok;
    Fb(k+1) = (rhok - Pk*M/(Ru*Tk))*Vbk*g0;
    A_b = pi*(Dbk/2)^2;
    Fd(k+1) = 0.5*rhok*cfg.balloon.cd*A_b*v(k+1)*abs(v(k+1));
    Mach(k+1) = abs(v(k+1))/ak;
    ReN(k+1) = rhok*abs(v(k+1))*Dbk/muk;

    if Dbk >= Dburst || h(k+1) >= cfg.mission.burst_alt_m
        N = k+1; break;
    end
end

t=t(1:N); h=h(1:N); v=v(1:N); Vb=Vb(1:N); Db=Db(1:N);
Tair=Tair(1:N); Pair=Pair(1:N); rho=rho(1:N);
Fb=Fb(1:N); Fd=Fd(1:N); Mach=Mach(1:N); ReN=ReN(1:N);
% Patch first sample
[Tair(1),Pair(1),rho(1)] = atm_us1976(h(1));
Vb(1)=V0; Db(1)=(6*V0/pi)^(1/3);
Fb(1) = (rho(1) - Pair(1)*M/(Ru*Tair(1)))*Vb(1)*g0;
Fd(1) = 0;

R = timetable(seconds(t), h, v, Vb, Db, Tair, Pair, rho, Fb, Fd, Mach, ReN, ...
   'VariableNames',{'alt_m','v_ms','Vb_m3','Db_m','T_K','P_Pa','rho','F_buoy_N','F_drag_N','Mach','Re'});
R.Properties.DimensionNames{1}='t';
R.Properties.UserData.apex_m   = h(end);
R.Properties.UserData.apex_t_s = t(end);
R.Properties.UserData.note     = 'Burst at simulated apex (US-1976 + ideal gas balloon)';

% =================================================================
    function [dh,dv] = deriv(~, h_, v_)
        [Tl,Pl,rhol,~,~] = atm_us1976(h_);
        Vbl = (n_gas*Ru*Tl)/Pl;
        Dbl = (6*Vbl/pi)^(1/3);
        rho_He = Pl*M/(Ru*Tl);
        Fb_ = (rhol - rho_He)*Vbl*g0;
        % Effective drag area = balloon frontal + payload frontal
        Ab  = pi*(Dbl/2)^2;
        Fdb = 0.5*rhol*cfg.balloon.cd*Ab*v_*abs(v_);
        Fdp = 0.5*rhol*cfg.payload.cd_box*cfg.payload.frontal_area_m2*v_*abs(v_);
        Fg  = m_tot*g0;
        F   = Fb_ - Fg - Fdb - Fdp;
        dv  = F/m_tot;
        dh  = v_;
    end
end
