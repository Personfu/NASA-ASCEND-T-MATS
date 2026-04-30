function f = viz_thermal_power(thermal, power, cfg)
%VIZ_THERMAL_POWER  Thermal + power dashboard.

co = cfg.plot.colors;

f = figure('Name','ASCEND-S26 Thermal & Power','Color','w','Position',[80 80 1400 850]);
tlay = tiledlayout(f,2,2,'TileSpacing','compact','Padding','compact');
title(tlay,'Lumped-capacitance thermal model & coulomb-counted power budget','FontWeight','bold','FontSize',13);

ax = nexttile;
plot(seconds(thermal.t)/60, thermal.T_box_C,'-','Color',co.thermal,'LineWidth',1.6); hold on;
plot(seconds(thermal.t)/60, thermal.T_air_C,'-','Color',co.ascent,'LineWidth',1.6);
yline(cfg.power.heater_setpoint_C,'--k','Heater setpoint');
grid on; xlabel('Elapsed (min)'); ylabel('Temperature (\circC)');
title('Box vs ambient temperature'); legend({'T_{box}','T_{air}'},'Location','best');

ax = nexttile;
plot(seconds(thermal.t)/60, thermal.Q_solar,'-','Color',[0.85 0.65 0.10],'LineWidth',1.2); hold on;
plot(seconds(thermal.t)/60, thermal.Q_albedo,'-','Color',[0.50 0.85 0.10],'LineWidth',1.0);
plot(seconds(thermal.t)/60, thermal.Q_earth_IR,'-','Color',[0.10 0.55 0.55],'LineWidth',1.0);
plot(seconds(thermal.t)/60, thermal.Q_box_IR,'-','Color',[0.55 0.10 0.10],'LineWidth',1.0);
plot(seconds(thermal.t)/60, thermal.Q_conv,'-','Color',[0.30 0.30 0.30],'LineWidth',1.0);
grid on; xlabel('Elapsed (min)'); ylabel('Heat flow (W)');
title('Heat balance components'); legend({'Solar','Albedo','Earth IR in','Box IR out','Convective'},'Location','best');

ax = nexttile;
yyaxis(ax,'left'); plot(seconds(power.t)/60, power.bus_power_W,'-','Color',[0.30 0.30 0.30],'LineWidth',1.4); ylabel('Bus power (W)');
yyaxis(ax,'right'); plot(seconds(power.t)/60, power.bus_current_A,'-','Color',[0.55 0.10 0.55],'LineWidth',1.4); ylabel('Bus current (A)');
grid on; xlabel('Elapsed (min)'); title('Bus power & current');

ax = nexttile;
yyaxis(ax,'left'); plot(seconds(power.t)/60, power.energy_used_Wh,'-','Color',[0.85 0.30 0.10],'LineWidth',1.6); ylabel('Energy used (Wh)');
yyaxis(ax,'right'); plot(seconds(power.t)/60, power.DoD_pct,'-','Color',[0.10 0.30 0.85],'LineWidth',1.6); ylabel('DoD (%)');
yline(80,'--r','80% DoD'); 
grid on; xlabel('Elapsed (min)'); title('Energy used & depth-of-discharge');

savefig_(f, fullfile(cfg.paths.figures,'06_thermal_power'), cfg);
end

function savefig_(f, base, cfg)
for k=1:numel(cfg.plot.export_formats)
    exportgraphics(f,[base,'.',cfg.plot.export_formats{k}],'Resolution',cfg.plot.dpi);
end
fprintf('  saved -> %s\n', base);
end
