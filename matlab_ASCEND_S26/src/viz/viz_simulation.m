function f = viz_simulation(D, cfg, sim)
%VIZ_SIMULATION  Compare simulated ascent/descent vs flown trajectory.

co = cfg.plot.colors;
T = D.trajectory;
A = sim.ascent; Dc = sim.descent;

f = figure('Name','ASCEND-S26 Simulation vs Flight','Color','w','Position',[80 80 1500 950]);
tlay = tiledlayout(f,2,3,'TileSpacing','compact','Padding','compact');
title(tlay,sprintf('ASCEND Spring 2026  -  Simulation vs Flight (Burst %.1f km / %.0f ft)', ...
    cfg.mission.burst_alt_m/1000, cfg.mission.burst_alt_ft), ...
    'FontWeight','bold','FontSize',13);

% --- altitude
ax = nexttile;
plot(ax, T.t_s/60, T.alt_m/1000, '.', 'Color',[0.20 0.20 0.20], 'MarkerSize',4); hold on;
plot(ax, seconds(A.t)/60, A.alt_m/1000, '-','Color',co.ascent,'LineWidth',2);
plot(ax, seconds(Dc.t)/60, Dc.alt_m/1000, '-','Color',co.descent,'LineWidth',2);
grid on; xlabel('Elapsed (min)'); ylabel('Altitude (km)');
title('Altitude vs Time'); legend({'Flight','Sim ascent','Sim descent'},'Location','best');

% --- velocity
ax = nexttile;
plot(ax, seconds(A.t)/60, A.v_ms, '-','Color',co.ascent,'LineWidth',2); hold on;
plot(ax, seconds(Dc.t)/60, Dc.v_ms, '-','Color',co.descent,'LineWidth',2);
plot(ax, T.t_s/60, T.vz_ms, '.','Color',[0.20 0.20 0.20], 'MarkerSize',4);
grid on; xlabel('Elapsed (min)'); ylabel('v_z (m/s)');
title('Vertical velocity'); legend({'Sim ascent','Sim descent','Flight'},'Location','best');

% --- balloon volume / diameter
ax = nexttile;
yyaxis(ax,'left'); plot(seconds(A.t)/60, A.Vb_m3,'-','Color',[0.10 0.45 0.85],'LineWidth',1.6); ylabel('V_{balloon} (m^3)');
yyaxis(ax,'right'); plot(seconds(A.t)/60, A.Db_m,'-','Color',[0.85 0.30 0.10],'LineWidth',1.6); ylabel('D_{balloon} (m)');
grid on; xlabel('Elapsed (min)'); title('Balloon expansion (ideal-gas)');

% --- buoyancy / drag forces
ax = nexttile;
plot(seconds(A.t)/60, A.F_buoy_N, '-','Color',[0.10 0.55 0.20],'LineWidth',1.6); hold on;
plot(seconds(A.t)/60, A.F_drag_N, '-','Color',[0.85 0.10 0.20],'LineWidth',1.6);
grid on; xlabel('Elapsed (min)'); ylabel('Force (N)');
title('Buoyancy & drag'); legend({'F_{buoy}','F_{drag}'},'Location','best');

% --- Mach / Re
ax = nexttile;
yyaxis(ax,'left'); plot(seconds(A.t)/60, A.Mach,'-','Color',[0.55 0.10 0.55],'LineWidth',1.4);
hold on; plot(seconds(Dc.t)/60, Dc.Mach,'-','Color',[0.10 0.55 0.55],'LineWidth',1.4); ylabel('Mach');
yyaxis(ax,'right'); semilogy(seconds(A.t)/60, A.Re,'-','Color',[0.30 0.30 0.30],'LineWidth',1.2); ylabel('Re_D');
grid on; xlabel('Elapsed (min)'); title('Mach (asc/dsc) & Reynolds (asc)');

% --- residuals (sim alt vs flight alt)
ax = nexttile;
ti = seconds(A.t);
flt = interp1(T.t_s, T.alt_m, ti, 'linear', NaN);
res = A.alt_m - flt;
plot(ti/60, res, '-','Color',[0.30 0.30 0.30]);
grid on; xlabel('Elapsed (min)'); ylabel('Sim - Flight (m)');
title('Residual (ascent only)');

savefig_(f, fullfile(cfg.paths.figures,'05_simulation'), cfg);
end

function savefig_(f, base, cfg)
for k=1:numel(cfg.plot.export_formats)
    exportgraphics(f,[base,'.',cfg.plot.export_formats{k}],'Resolution',cfg.plot.dpi);
end
fprintf('  saved -> %s\n', base);
end
