function viz_payload_thermal_skin(PE, cfg, D)
%VIZ_PAYLOAD_THERMAL_SKIN  High-altitude balloon skin/core thermal
%   model for the Spring 2026 carbon-fiber payload (Personfu).
%
%   Two-node lumped-capacitance balance with altitude-dependent
%   convective coefficient, full-spectrum solar absorption, IR
%   exchange with sky/Earth, and internal electronics dissipation.
%
%   Energy balance per node (skin s, core c):
%       Cs dTs/dt = Q_solar + Q_albedo + Q_earth_IR
%                   - eps*sigma*A*(Ts^4 - Tsky^4)
%                   - h_c*A*(Ts - T_amb) - UA_wall*(Ts - Tc)
%       Cc dTc/dt = Q_internal + UA_wall*(Ts - Tc)
%
%   Inputs:  PE  - payload_engineering struct
%            cfg - mission config
%            D   - ingested mission data (uses trajectory altitude)
%
%   Output: figures/17_payload_thermal_skin.{png,pdf}

if nargin<3 || ~isfield(D,'trajectory') || height(D.trajectory)<10
    warning('viz_payload_thermal_skin: trajectory missing, synthesizing'); 
    t_min = (0:1:120).'; alt_m = 100 + 7.3*60*t_min;     % synth ascent
    alt_m(t_min>60) = max(alt_m(t_min<=60)) - 12.6*60*(t_min(t_min>60)-60);
    alt_m = max(alt_m,300);
    tt = (0:60:7200).';
else
    T = D.trajectory;
    tt    = seconds(T.Time - T.Time(1));
    alt_m = T.alt_m;
end
tt = tt(:); alt_m = alt_m(:);

% atmosphere along trajectory
[T_amb, p_amb, rho_amb] = arrayfun(@local_atm, alt_m);

% radiation environment
S0   = 1361;            % W/m2 solar constant (top-of-atmosphere)
albedo = 0.30;
T_earth = 255;          % effective IR temperature
sigma = 5.670374419e-8;
beta_sun = deg2rad(40); % solar elevation March-late afternoon AZ
S_alt = S0 * exp(-(0.10*p_amb./101325));   % crude atmospheric attenuation
S_alt = max(S0*0.40, S_alt);

% geometry
A_proj = pi*(PE.geometry.body_OD_mm/2000) * (PE.geometry.body_H_mm/1000); % side-projected
A_out  = PE.thermal.A_outer_m2;
alpha  = PE.thermal.alpha_solar;
eps_ir = PE.thermal.eps_LWIR;
UAw    = PE.thermal.UA_wall_W_K;
Cs     = 0.30 * PE.totals.mass_kg * 900;    % skin lumped (30% mass)
Cc     = 0.70 * PE.totals.mass_kg * 900;    % core lumped (70% mass)
Qint   = PE.thermal.Q_internal_W;

% convective h: free convection at ground -> ~10 W/m2K, near-vacuum -> ~0.5
h_c = 10 * exp(-alt_m/8000) + 0.5;

% interpolators
Tamb_i = @(s) interp1(tt,T_amb,s,'linear','extrap');
S_i    = @(s) interp1(tt,S_alt.*sin(beta_sun),s,'linear','extrap');
hc_i   = @(s) interp1(tt,h_c,s,'linear','extrap');

% RK4 integration
dt   = 5;
tsim = (tt(1):dt:tt(end)).';
Ts = nan(size(tsim)); Tc = nan(size(tsim));
Ts(1) = T_amb(1)+5; Tc(1) = T_amb(1)+5;
for k = 1:numel(tsim)-1
    s = tsim(k); Tsk = Ts(k); Tck = Tc(k);
    [k1s,k1c] = rates(s,         Tsk,            Tck);
    [k2s,k2c] = rates(s+dt/2,    Tsk+dt/2*k1s,   Tck+dt/2*k1c);
    [k3s,k3c] = rates(s+dt/2,    Tsk+dt/2*k2s,   Tck+dt/2*k2c);
    [k4s,k4c] = rates(s+dt,      Tsk+dt*k3s,     Tck+dt*k3c);
    Ts(k+1) = Tsk + dt/6*(k1s+2*k2s+2*k3s+k4s);
    Tc(k+1) = Tck + dt/6*(k1c+2*k2c+2*k3c+k4c);
end
alt_i = interp1(tt,alt_m,tsim,'linear','extrap');
Tamb_t = Tamb_i(tsim);

% ===== plot =======================================================
f = figure('Color','w','Position',[40 40 1500 920], ...
    'Name','Payload thermal skin (Personfu)');
tl = tiledlayout(f,2,2,'TileSpacing','compact','Padding','compact');

ax = nexttile; hold(ax,'on'); grid(ax,'on'); box(ax,'on');
plot(ax, tsim/60, Ts-273.15,'-','Color',[0.85 0.10 0.10],'LineWidth',1.5,'DisplayName','skin T_s');
plot(ax, tsim/60, Tc-273.15,'-','Color',[0.10 0.30 0.85],'LineWidth',1.5,'DisplayName','core T_c');
plot(ax, tsim/60, Tamb_t-273.15,':','Color',[0.3 0.3 0.3],'LineWidth',1.0,'DisplayName','T_{amb}');
xlabel(ax,'time (min)'); ylabel(ax,'T (\circC)'); legend(ax,'Location','best');
title(ax,'Two-node thermal evolution','FontWeight','bold');

ax = nexttile; hold(ax,'on'); grid(ax,'on'); box(ax,'on');
plot(ax, alt_i/1000, Ts-273.15,'-','Color',[0.85 0.10 0.10],'LineWidth',1.4,'DisplayName','skin');
plot(ax, alt_i/1000, Tc-273.15,'-','Color',[0.10 0.30 0.85],'LineWidth',1.4,'DisplayName','core');
plot(ax, alt_i/1000, Tamb_t-273.15,':','Color',[0.3 0.3 0.3],'DisplayName','T_{amb}');
xlabel(ax,'altitude (km)'); ylabel(ax,'T (\circC)'); legend(ax,'Location','best');
title(ax,'Skin/core vs altitude','FontWeight','bold');

% heat-flow stack at ascent midpoint
ax = nexttile; hold(ax,'on'); grid(ax,'on'); box(ax,'on');
half = round(numel(tsim)/2);
[Qs, Qa, Qe, Qrad, Qconv, Qwall] = local_heat_breakdown(tsim(half), Ts(half), Tc(half));
labs = {'solar','albedo','earth IR','radiative','convection','wall'};
vals = [Qs Qa Qe -Qrad -Qconv -Qwall]*A_out;
bar(ax, vals,'FaceColor',[0.95 0.65 0.10],'EdgeColor','k');
set(ax,'XTick',1:numel(labs),'XTickLabel',labs);
ylabel(ax,'Q (W)'); title(ax,'Skin power balance (mid-ascent)','FontWeight','bold');

% time-constant + min/max
ax = nexttile; hold(ax,'on'); grid(ax,'on'); box(ax,'on');
metrics = {sprintf('skin min  %.1f \\circC', min(Ts-273.15)), ...
           sprintf('skin max  %.1f \\circC', max(Ts-273.15)), ...
           sprintf('core min  %.1f \\circC', min(Tc-273.15)), ...
           sprintf('core max  %.1f \\circC', max(Tc-273.15)), ...
           sprintf('\\tau     %.0f s',       Cc/UAw), ...
           sprintf('Q_{int}   %.2f W',       Qint), ...
           sprintf('UA_{wall} %.2f W/K',    UAw)};
text(ax, 0.05, 0.95, strjoin(metrics, char(10)), ...
    'Units','normalized','FontName','Consolas','FontSize',10, ...
    'VerticalAlignment','top');
axis(ax,'off');
title(ax,'Headline thermal metrics','FontWeight','bold');

title(tl, sprintf('%s  -  Two-node thermal model (Personfu)', PE.name), ...
      'FontWeight','bold','FontSize',13);

out = fullfile(cfg.paths.figures,'17_payload_thermal_skin');
exportgraphics(f,[out '.png'],'Resolution',cfg.plot.dpi);
exportgraphics(f,[out '.pdf'],'ContentType','vector');
fprintf('  viz_payload_thermal_skin -> %s.{png,pdf}\n', out);

% =========== nested rates =========================================
function [dTs,dTc] = rates(s, Ts_, Tc_)
    Tamb = Tamb_i(s); Sflux = S_i(s); h = hc_i(s);
    Tsky = 220;
    Q_solar  = alpha * Sflux * A_proj;
    Q_albedo = alpha * 0.5*S0*albedo*A_proj * 0.4;
    Q_earth  = eps_ir * sigma * A_out * (T_earth^4) * 0.5;
    Q_rad    = eps_ir * sigma * A_out * (Ts_^4 - Tsky^4);
    Q_conv   = h * A_out * (Ts_ - Tamb);
    Q_wall   = UAw * (Ts_ - Tc_);
    dTs = (Q_solar + Q_albedo + Q_earth - Q_rad - Q_conv - Q_wall) / Cs;
    dTc = (Qint + Q_wall) / Cc;
end

function [Qs,Qa,Qe,Qrad,Qconv,Qwall] = local_heat_breakdown(s,Ts_,Tc_)
    Tamb = Tamb_i(s); Sflux = S_i(s); h = hc_i(s);
    Tsky = 220;
    Qs   = alpha*Sflux;
    Qa   = alpha*0.5*S0*albedo*0.4;
    Qe   = eps_ir*sigma*(T_earth^4)*0.5;
    Qrad = eps_ir*sigma*(Ts_^4 - Tsky^4);
    Qconv= h*(Ts_ - Tamb);
    Qwall= UAw*(Ts_-Tc_)/A_out;
end

end

% ==================================================================
function [T,p,rho] = local_atm(h)
% US-1976 (compact, troposphere/stratosphere)
g0=9.80665; R=287.05;
if h < 11000
    T = 288.15 - 0.0065*h;
    p = 101325*(T/288.15)^(g0/(R*0.0065));
elseif h < 20000
    T = 216.65;
    p = 22632.06*exp(-g0*(h-11000)/(R*T));
elseif h < 32000
    T = 216.65 + 0.001*(h-20000);
    p = 5474.89 *(216.65/T)^(g0/(R*0.001));
else
    T = 228.65 + 0.0028*(h-32000);
    p = 868.02 *(228.65/T)^(g0/(R*0.0028));
end
rho = p/(R*T);
end
