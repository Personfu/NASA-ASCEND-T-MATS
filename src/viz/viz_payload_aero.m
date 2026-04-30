function viz_payload_aero(PE, cfg)
%VIZ_PAYLOAD_AERO  Aerodynamics dashboard for the cylindrical payload
%   under axial / cross / descent attitudes.  Designed by Personfu.
%
%   Computes:
%     - drag force vs altitude assuming descent at terminal velocity
%       under the parachute (canopy CdA from payload_systems if
%       available, otherwise from PE.aero)
%     - Reynolds number along ascent and descent profiles
%     - vortex-shedding Strouhal frequency on the cylinder side
%     - pressure coefficient distribution around the cylinder (potential
%       flow + empirical correction for separation)
%
%   Output: figures/18_payload_aero.{png,pdf}

A = PE.aero;
m = PE.totals.mass_kg;
g = 9.80665;
CdA_canopy = 0.85 * 1.50;   % spec descent canopy area * Cd

h = linspace(0, 25500, 200).';
[Ta, pa, rhoa] = arrayfun(@local_atm, h);

% terminal velocity under canopy
Vt = sqrt(2*m*g ./ (rhoa * CdA_canopy));     % m/s
% Reynolds on body cross-section
mu = 1.458e-6 .* (Ta.^1.5)./(Ta+110.4);
Re = rhoa .* Vt * A.D_m ./ mu;
% Strouhal vortex-shedding frequency (St ~ 0.21 for cyl in subcritical)
St = 0.21;
fv = St * Vt / A.D_m;
% Mach
a_sound = sqrt(1.4*287.05*Ta);
M  = Vt ./ a_sound;

% pressure coefficient around cylinder
theta = linspace(0,pi,180);
Cp_pot = 1 - 4*sin(theta).^2;
% empirical separation: clamp Cp at theta>~120deg to -1.2
Cp_emp = Cp_pot;
sep = theta > deg2rad(110);
Cp_emp(sep) = -1.2 + 0.05*(theta(sep)-deg2rad(110));

% drag force along descent
F_drag = 0.5 * rhoa .* Vt.^2 * CdA_canopy;

f = figure('Color','w','Position',[40 40 1500 920], ...
    'Name','Payload aerodynamics (Personfu)');
tl = tiledlayout(f,2,2,'TileSpacing','compact','Padding','compact');

ax = nexttile; hold(ax,'on'); grid(ax,'on'); box(ax,'on');
plot(ax, Vt, h/1000,'-','Color',[0.10 0.45 0.85],'LineWidth',1.5);
xlabel(ax,'terminal V (m/s)'); ylabel(ax,'altitude (km)');
title(ax,'Descent terminal velocity','FontWeight','bold');

ax = nexttile; hold(ax,'on'); grid(ax,'on'); box(ax,'on');
semilogx(ax, Re, h/1000,'-','Color',[0.85 0.10 0.45],'LineWidth',1.5);
xlabel(ax,'Re_D (cylinder)'); ylabel(ax,'altitude (km)');
xline(ax,3.5e5,'--k','sub-critical limit');
title(ax,'Reynolds along descent','FontWeight','bold');

ax = nexttile; hold(ax,'on'); grid(ax,'on'); box(ax,'on');
plot(ax, theta*180/pi, Cp_pot,'--','Color',[0.4 0.4 0.4],'DisplayName','potential');
plot(ax, theta*180/pi, Cp_emp,'-','Color',[0.95 0.55 0.10],'LineWidth',1.6,'DisplayName','separated');
xlabel(ax,'\theta (deg)'); ylabel(ax,'C_p');
legend(ax,'Location','best'); title(ax,'C_p around cylinder','FontWeight','bold');

ax = nexttile; hold(ax,'on'); grid(ax,'on'); box(ax,'on');
yyaxis(ax,'left');
plot(ax, h/1000, fv,'-','Color',[0.55 0.10 0.65],'LineWidth',1.5);
ylabel(ax,'vortex shedding f (Hz)');
yyaxis(ax,'right');
plot(ax, h/1000, F_drag,'-','Color',[0.10 0.55 0.20],'LineWidth',1.5);
ylabel(ax,'drag force (N)');
xlabel(ax,'altitude (km)');
title(ax,'Shedding frequency / drag force','FontWeight','bold');

title(tl,sprintf('%s aerodynamics  -  D=%.0f mm, L=%.2f m, m=%.3f kg', ...
    PE.name, A.D_m*1000, A.L_m, m), 'FontWeight','bold','FontSize',13);

out = fullfile(cfg.paths.figures,'18_payload_aero');
exportgraphics(f,[out '.png'],'Resolution',cfg.plot.dpi);
exportgraphics(f,[out '.pdf'],'ContentType','vector');
fprintf('  viz_payload_aero       -> %s.{png,pdf}\n', out);
end

function [T,p,rho] = local_atm(h)
g0=9.80665; R=287.05;
if h < 11000
    T = 288.15 - 0.0065*h; p = 101325*(T/288.15)^(g0/(R*0.0065));
elseif h < 20000
    T = 216.65; p = 22632.06*exp(-g0*(h-11000)/(R*T));
elseif h < 32000
    T = 216.65 + 0.001*(h-20000); p = 5474.89*(216.65/T)^(g0/(R*0.001));
else
    T = 228.65 + 0.0028*(h-32000); p = 868.02*(228.65/T)^(g0/(R*0.0028));
end
rho = p/(R*T);
end
