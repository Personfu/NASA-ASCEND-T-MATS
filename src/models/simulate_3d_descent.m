function R = simulate_3d_descent(cfg, wind, x0_ENU, v0_ENU)
%SIMULATE_3D_DESCENT  3-DOF parachute descent with opening shock and wind drift.
%
%   R = SIMULATE_3D_DESCENT(cfg, wind, x0_ENU, v0_ENU)
%
%   Models:
%     1. Free-fall after burst with debris (balloon film) attached
%     2. Parachute opening transient using Pflanz-style canopy filling:
%           Cd*A(t) = Cd*A_inf * (t/t_fill)^p   for 0<t<t_fill
%        where t_fill = n*D_p / v_rel  (n=8 nominal for hemispherical)
%     3. Steady-state descent with altitude-dependent rho
%     4. Lateral wind drift integrated continuously

g0   = cfg.atm.g0;
m    = cfg.payload.total_mass_kg;
CdAp = cfg.parachute.cd * cfg.parachute.area_m2;
Dp   = cfg.parachute.diameter_m;
n_fill = 8;                               % canopy filling exponent constant
p_fill = 2.0;                             % power-law exponent (2 = quadratic)

dt = 0.25; tmax = 6000;
N = ceil(tmax/dt);
[X,V] = deal(zeros(N,3));
X(1,:) = x0_ENU; V(1,:) = v0_ENU;
[CdA_t, F_shock, Mach, rho_a] = deal(zeros(N,1));
t = (0:N-1)*dt;
opened = false; t_open = 0; t_fill = 0;

for k = 1:N-1
    h = X(k,3);
    [Tk,~,rk,ak,~] = atm_us1976(max(h,0));
    rho_a(k)=rk; Mach(k)=norm(V(k,:))/ak;

    [u_w,v_w] = wind.profile(h);
    v_rel = V(k,:) - [u_w,v_w,0];

    % Canopy state
    if ~opened && norm(v_rel) > 5
        opened = true; t_open = t(k);
        t_fill = n_fill*Dp/max(norm(v_rel),1);
    end
    if opened
        tau = (t(k)-t_open)/max(t_fill,1e-3);
        f   = min(tau^p_fill, 1.0);
        CdA = CdAp*f + cfg.payload.cd_box*cfg.payload.frontal_area_m2;
    else
        CdA = cfg.payload.cd_box*cfg.payload.frontal_area_m2 ...
            + 0.05*pi*(cfg.balloon.burst_diam_m/2)^2;     % shredded film
    end
    CdA_t(k) = CdA;
    Fdrag = -0.5*rk*CdA*norm(v_rel)*v_rel;
    F_shock(k) = norm(Fdrag);

    a = Fdrag/m + [0,0,-g0];
    V(k+1,:) = V(k,:) + a*dt;
    X(k+1,:) = X(k,:) + V(k+1,:)*dt;

    if X(k+1,3) <= cfg.mission.launch_alt_m
        N = k+1; break;
    end
end
t=t(1:N).'; X=X(1:N,:); V=V(1:N,:); CdA_t=CdA_t(1:N);
F_shock=F_shock(1:N); Mach=Mach(1:N); rho_a=rho_a(1:N);

R = timetable(seconds(t), X(:,1),X(:,2),X(:,3), V(:,1),V(:,2),V(:,3), ...
              sqrt(sum(V.^2,2)), CdA_t, F_shock, Mach, rho_a, ...
    'VariableNames',{'x_E','x_N','x_U','v_E','v_N','v_U','speed', ...
                     'CdA_m2','F_shock_N','Mach','rho'});
R.Properties.DimensionNames{1}='t';
R.Properties.UserData.peak_shock_N = max(F_shock);
R.Properties.UserData.peak_g       = max(F_shock)/(m*g0);
R.Properties.UserData.impact_v_ms  = norm(V(end,:));
R.Properties.UserData.drift_km     = norm(X(end,1:2)-X(1,1:2))/1000;
end
