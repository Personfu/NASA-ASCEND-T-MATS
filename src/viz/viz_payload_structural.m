function viz_payload_structural(PE, cfg)
%VIZ_PAYLOAD_STRUCTURAL  FEA-lite structural analysis dashboard for
%   the Spring 2026 carbon-fiber payload.  Designed by Personfu.
%
%   Computes and visualizes:
%     (1) Axial column stress along the body height under burst-shock
%         load (12 g impact case) -- thin-shell beam approximation
%             sigma(z) = N(z)/A(z) + M_bending*r/I_shell
%         where N(z) is mass below + payload weight under load factor.
%     (2) Hoop stress vs internal pressure differential
%             sigma_hoop = dP * R / t
%     (3) Euler buckling envelope vs L/R (column with K=0.7)
%             P_cr = pi^2 E I_shell / (K L)^2
%     (4) Bridle-pad bearing stress and margin of safety vs load case.
%     (5) First-order modal estimate of the cylindrical body
%             f1 ~ (1.875^2 / (2 pi L^2)) * sqrt(E I / (rho A))
%     (6) Material allowables vs working stress radar plot.
%
%   Output: figures/16_payload_structural.{png,pdf}

L = PE.geometry.body_H_mm/1000;
R = PE.geometry.body_OD_mm/2000;
t = PE.geometry.skin_t_mm/1000;
E = PE.materials.cf_wrap.E1_GPa*1e9;
rho_eff = PE.totals.mass_kg / (pi*R^2*L);
A_xs    = 2*pi*R*t;
I_shell = pi*R^3*t;
m_tot   = PE.totals.mass_kg;
g0      = 9.80665;

% ---- (1) axial stress profile -----------------------------------
nz = 80;
z = linspace(0,L,nz);
n_factor = PE.loads.shock_g;                      % 12 g
% N(z) = mass above z * load factor * g
massAbove = m_tot * (1 - z/L);                    % uniform smear
N = massAbove * n_factor * g0;                    % N
sigma_axial = N / A_xs / 1e6;                     % MPa

% ---- (2) hoop stress vs dP --------------------------------------
dP = linspace(0,10000,200);
sigma_hoop = dP*R/t/1e6;

% ---- (3) buckling vs slenderness --------------------------------
Lvec = linspace(0.05,0.6,200);
P_cr = pi^2 * E * I_shell ./ (0.7*Lvec).^2;
P_load = m_tot*g0*PE.loads.shock_g;

% ---- (4) bridle bearing -----------------------------------------
load_cases = {'launch','burst','shock','landing'};
gvec = [PE.loads.launch_g PE.loads.burst_g 6.211 PE.loads.shock_g];
F = m_tot * g0 * gvec;
A_pad = PE.loads.A_susp_mm2*1e-6;                 % m2
sigma_pad_MPa = (F/A_pad)/1e6;

% ---- (5) modal beam frequency -----------------------------------
f1 = (1.875^2/(2*pi*L^2)) * sqrt(E*I_shell/(rho_eff*A_xs));

% ---- (6) radar of allowables ------------------------------------
labels = {'CF tension','CF compression','PETG-CF yield','Hoop','Buckling','Bearing'};
allow  = [PE.materials.cf_wrap.sigma_t_MPa, PE.materials.cf_wrap.sigma_c_MPa, ...
          PE.materials.printed.sigma_y_MPa, ...
          PE.materials.cf_wrap.sigma_t_MPa*0.5, ...
          P_cr(end)/A_xs/1e6, PE.materials.cf_wrap.sigma_t_MPa*0.5];
work   = [max(sigma_axial), max(sigma_axial), max(sigma_axial), ...
          max(sigma_hoop),  P_load/A_xs/1e6,  max(sigma_pad_MPa)];

% =================================================================
f = figure('Color','w','Position',[40 40 1620 980], ...
    'Name','Payload structural FEA-lite (Personfu)');
tl = tiledlayout(f,2,3,'TileSpacing','compact','Padding','compact');

ax = nexttile; hold(ax,'on'); grid(ax,'on'); box(ax,'on');
plot(ax, sigma_axial, z*1000, '-', 'Color',[0.85 0.10 0.45],'LineWidth',1.5);
xlabel(ax,'\sigma_{axial} (MPa)'); ylabel(ax,'height z (mm)');
xline(ax, PE.materials.printed.sigma_y_MPa,'--k','PETG-CF \sigma_y');
title(ax,sprintf('Axial stress @ %.1f g shock', n_factor),'FontWeight','bold');

ax = nexttile; hold(ax,'on'); grid(ax,'on'); box(ax,'on');
plot(ax, dP/1000, sigma_hoop, '-','Color',[0.10 0.45 0.85],'LineWidth',1.5);
xlabel(ax,'\DeltaP (kPa)'); ylabel(ax,'\sigma_{hoop} (MPa)');
yline(ax, PE.materials.cf_wrap.sigma_t_MPa*0.5,'--k','0.5 \sigma_{t,CF}');
title(ax,'Hoop stress (vented enclosure)','FontWeight','bold');

ax = nexttile; hold(ax,'on'); grid(ax,'on'); box(ax,'on');
plot(ax, Lvec*1000, P_cr/1000, '-','Color',[0.10 0.55 0.20],'LineWidth',1.5);
yline(ax, P_load/1000, '--r', sprintf('shock load %.0f N',P_load));
xline(ax, L*1000,':k','design L');
xlabel(ax,'column length L (mm)'); ylabel(ax,'P_{cr} (kN)');
set(ax,'YScale','log'); title(ax,'Euler buckling envelope','FontWeight','bold');

ax = nexttile; hold(ax,'on'); grid(ax,'on'); box(ax,'on');
b = bar(ax, sigma_pad_MPa,'FaceColor',[0.95 0.55 0.10],'EdgeColor','k');
set(ax,'XTick',1:numel(load_cases),'XTickLabel',load_cases);
ylabel(ax,'bridle bearing \sigma (MPa)');
yline(ax, PE.materials.cf_wrap.sigma_t_MPa*0.5,'--k','allowable');
title(ax,sprintf('Bridle pad stress (A=%.1f mm^2)', PE.loads.A_susp_mm2),'FontWeight','bold');
for k=1:numel(load_cases)
    text(ax,k,sigma_pad_MPa(k)+1,sprintf('%.1f',sigma_pad_MPa(k)), ...
        'HorizontalAlignment','center','FontSize',8);
end

ax = nexttile; hold(ax,'on'); grid(ax,'on'); box(ax,'on');
freqs = f1 * [1, 6.27/1.875^2*4.694^2/4.694^2, 0]; %#ok<NASGU>
fbeam = (1.875^2/(2*pi*L^2)) * sqrt(E*I_shell/(rho_eff*A_xs));
fmodes = fbeam * [1, (4.694/1.875)^2, (7.855/1.875)^2];
bar(ax, fmodes, 'FaceColor',[0.55 0.10 0.65],'EdgeColor','k');
set(ax,'XTickLabel',{'mode 1','mode 2','mode 3'});
ylabel(ax,'natural frequency (Hz)');
title(ax,sprintf('Cantilever modal estimate (f_1 = %.0f Hz)', fbeam),'FontWeight','bold');

% radar
ax = nexttile; hold(ax,'on');
n = numel(labels); ang = linspace(0,2*pi,n+1);
allow_n = allow ./ max(allow);
work_n  = work  ./ max(allow);
polarplot_local(ax, ang, [allow_n allow_n(1)], [0.10 0.55 0.20]);
polarplot_local(ax, ang, [work_n  work_n(1)],  [0.85 0.10 0.45]);
set(ax,'XTick',[],'YTick',[]); axis(ax,'equal'); axis(ax,'off');
for k=1:n
    text(ax, 1.15*cos(ang(k)),1.15*sin(ang(k)),labels{k}, ...
        'FontSize',9,'HorizontalAlignment','center');
end
title(ax,'Allowable (green) vs working (red)  -  normalized','FontWeight','bold');

title(tl, sprintf(['Phoenix-1 structural margins  -  ' ...
    'm=%.3f kg, R=%.0f mm, t=%.2f mm  (Personfu)'], ...
    m_tot, R*1000, t*1000),'FontWeight','bold','FontSize',13);

out = fullfile(cfg.paths.figures,'16_payload_structural');
exportgraphics(f,[out '.png'],'Resolution',cfg.plot.dpi);
exportgraphics(f,[out '.pdf'],'ContentType','vector');
fprintf('  viz_payload_structural -> %s.{png,pdf}\n', out);

% margins summary to disk
S = struct('axial_max_MPa',max(sigma_axial), ...
           'hoop_at_5kPa_MPa',5000*R/t/1e6, ...
           'P_cr_N',pi^2*E*I_shell/(0.7*L)^2, ...
           'P_load_N',P_load,'MS_buckle',pi^2*E*I_shell/(0.7*L)^2/P_load - 1, ...
           'sigma_pad_MPa',sigma_pad_MPa,'f_modes_Hz',fmodes);
save(fullfile(cfg.paths.data_proc,'payload_structural.mat'),'S');
end

% ------------------------------------------------------------------
function polarplot_local(ax,theta,r,col)
x = r.*cos(theta); y = r.*sin(theta);
fill(ax,x,y,col,'FaceAlpha',0.18,'EdgeColor',col,'LineWidth',1.6);
plot(ax,x,y,'o','MarkerFaceColor',col,'MarkerEdgeColor','k','MarkerSize',4);
end
