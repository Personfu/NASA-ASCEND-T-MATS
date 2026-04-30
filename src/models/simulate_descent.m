function R = simulate_descent(cfg, t0_s, h0_m)
%SIMULATE_DESCENT  Parachute descent from burst altitude to ground.
%
%   R = SIMULATE_DESCENT(cfg, t0_s, h0_m) integrates ballistic free-fall
%   followed by parachute-stabilized descent, accounting for variable
%   atmospheric density.
%
%       m dv/dt = -m g + 1/2 rho Cd A v|v|     (v negative = falling)
%
%   Effective Cd*A combines parachute (deployed instantly at burst per
%   ASCEND payload spec - no reefing) and the payload box.

if nargin<2 || isempty(t0_s), t0_s = 0; end
if nargin<3 || isempty(h0_m), h0_m = cfg.mission.burst_alt_m; end

g0 = cfg.atm.g0;
m  = cfg.payload.total_mass_kg + cfg.balloon.mass_kg*0.30;  % residual latex
CdA = cfg.chute.cd*cfg.chute.area_m2 + cfg.payload.cd_box*cfg.payload.frontal_area_m2;

dt = 0.5;
tmax = 90*60;            % 90 min cap
N = ceil(tmax/dt);
[t,h,v,Tair,Pair,rho,Mach] = deal(zeros(N,1));
h(1) = h0_m; v(1) = 0; t(1) = t0_s;

for k = 1:N-1
    [k1h,k1v] = deriv(h(k),         v(k));
    [k2h,k2v] = deriv(h(k)+dt/2*k1h,v(k)+dt/2*k1v);
    [k3h,k3v] = deriv(h(k)+dt/2*k2h,v(k)+dt/2*k2v);
    [k4h,k4v] = deriv(h(k)+dt*k3h,  v(k)+dt*k3v);
    h(k+1) = h(k) + dt/6*(k1h+2*k2h+2*k3h+k4h);
    v(k+1) = v(k) + dt/6*(k1v+2*k2v+2*k3v+k4v);
    t(k+1) = t(k) + dt;

    [Tk,Pk,rhok,ak] = atm_us1976(max(h(k+1),0));
    Tair(k+1)=Tk; Pair(k+1)=Pk; rho(k+1)=rhok; Mach(k+1)=abs(v(k+1))/ak;

    if h(k+1) <= cfg.mission.launch_alt_m, N=k+1; break; end
end

t=t(1:N); h=h(1:N); v=v(1:N); Tair=Tair(1:N); Pair=Pair(1:N);
rho=rho(1:N); Mach=Mach(1:N);
[Tair(1),Pair(1),rho(1),~] = atm_us1976(h(1));

R = timetable(seconds(t), h, v, Tair, Pair, rho, Mach, ...
    'VariableNames',{'alt_m','v_ms','T_K','P_Pa','rho','Mach'});
R.Properties.DimensionNames{1}='t';
R.Properties.UserData.impact_v_ms = v(end);
R.Properties.UserData.impact_v_mph = v(end)/0.44704;
R.Properties.UserData.peak_v_ms   = min(v);
R.Properties.UserData.peak_v_mph  = min(v)/0.44704;

% =================================================================
    function [dh,dv] = deriv(h_, v_)
        [~,~,rhol] = atm_us1976(max(h_,0));
        Fd = 0.5*rhol*CdA*v_*abs(v_);   % opposes motion (v<0 -> Fd>0)
        dv = -g0 - Fd/m;                 % falling: drag positive (up)
        dh = v_;
    end
end
