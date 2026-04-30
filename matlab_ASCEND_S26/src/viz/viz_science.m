function f = viz_science(D, cfg)
%VIZ_SCIENCE  Cosmic-ray (Pfotzer-Regener), UV/ozone, PM, CO2 dashboard.

co = cfg.plot.colors;
G = D.geiger;  M = D.multi;  A = D.arduino; T = D.trajectory;

% Map Geiger time -> altitude by interpolation against trajectory
t_T = T.t_s; alt_T = T.alt_m;
[t_T_u, ia] = unique(t_T); alt_u = alt_T(ia);
G.alt_m = interp1(t_T_u, alt_u, G.t_s, 'linear', NaN);
M.alt_m = interp1(t_T_u, alt_u, M.t_s, 'linear', NaN);
A.alt_m = interp1(t_T_u, alt_u, A.t_s, 'linear', NaN);

% Predicted Pfotzer curve
hgrid = (0:200:30000)';
PR = model_cosmic_ray(cfg, hgrid);

% Predicted UV at flight times
UV = model_uv_ozone(cfg, A.alt_m, A.time_utc);

f = figure('Name','ASCEND-S26 Science','Color','w','Position',[80 80 1500 950]);
tlay = tiledlayout(f,3,2,'TileSpacing','compact','Padding','compact');
title(tlay,'Phoenix College ASCEND - Spring 2026 - Science Payload','FontWeight','bold','FontSize',13);

% (1) Cosmic ray dose vs altitude (Pfotzer-Regener)
ax = nexttile; 
plot(ax, PR.dose_uSvph, PR.alt_m/1000, '-', 'Color',co.cosmic,'LineWidth',2); hold on;
ok = ~isnan(G.alt_m);
scatter(ax, G.dose_uSvph(ok), G.alt_m(ok)/1000, 12, [0.10 0.10 0.10],'filled','MarkerFaceAlpha',0.4);
yline(ax, cfg.science.pfotzer_alt_m/1000, '--k', 'Pfotzer max');
grid on; xlabel('Dose (\muSv/h)'); ylabel('Altitude (km)');
title('Cosmic-ray dose - Pfotzer-Regener'); legend({'Model','GMC-320+'},'Location','best');

% (2) CPM vs time
ax = nexttile;
plot(ax, G.t_s/60, G.cpm, '-', 'Color',co.cosmic,'LineWidth',1.0);
grid on; xlabel('Elapsed (min)'); ylabel('CPM'); title('Geiger counts/minute');

% (3) UV irradiance vs altitude (model + sensor)
ax = nexttile;
ok = ~isnan(A.alt_m);
plot(ax, UV.UVA_mWcm2, A.alt_m/1000, '-', 'Color',[0.55 0.10 0.65],'LineWidth',2); hold on;
plot(ax, UV.UVB_mWcm2, A.alt_m/1000, '-', 'Color',[0.85 0.30 0.10],'LineWidth',2);
plot(ax, UV.UVC_mWcm2, A.alt_m/1000, '-', 'Color',[0.10 0.30 0.85],'LineWidth',2);
scatter(ax, A.UVA_mWcm2(ok), A.alt_m(ok)/1000, 6, [0.55 0.10 0.65],'filled','MarkerFaceAlpha',0.25);
scatter(ax, A.UVB_mWcm2(ok), A.alt_m(ok)/1000, 6, [0.85 0.30 0.10],'filled','MarkerFaceAlpha',0.25);
scatter(ax, A.UVC_mWcm2(ok), A.alt_m(ok)/1000, 6, [0.10 0.30 0.85],'filled','MarkerFaceAlpha',0.25);
grid on; xlabel('Irradiance (mW/cm^2)'); ylabel('Altitude (km)');
title('UV irradiance vs altitude (Beer-Lambert + Hartley-Huggins)');
legend({'UVA model','UVB model','UVC model','UVA sensor','UVB sensor','UVC sensor'}, ...
    'Location','best','FontSize',8);

% (4) PM2.5 / PM10 vs altitude
ax = nexttile;
ok = ~isnan(M.alt_m);
plot(ax, M.pm25(ok), M.alt_m(ok)/1000, '.', 'Color',co.pm,'MarkerSize',6); hold on;
plot(ax, M.pm100(ok), M.alt_m(ok)/1000, '.', 'Color',[0.85 0.55 0.10],'MarkerSize',6);
grid on; xlabel('PM (\mug/m^3)'); ylabel('Altitude (km)');
title('Particulate matter profile'); legend({'PM2.5','PM10'},'Location','best');

% (5) CO2 vs altitude
ax = nexttile;
plot(ax, M.co2_ppm(ok), M.alt_m(ok)/1000, '.', 'Color',co.co2,'MarkerSize',6);
grid on; xlabel('CO_2 (ppm)'); ylabel('Altitude (km)');
title('CO_2 concentration vs altitude');

% (6) Temp & RH
ax = nexttile;
yyaxis(ax,'left'); plot(ax, M.t_s/60, M.temp_C, '-','Color',co.thermal); ylabel('T (\circC)');
yyaxis(ax,'right'); plot(ax, M.t_s/60, M.rh_pct, '-','Color',[0.10 0.30 0.55]); ylabel('RH (%)');
grid on; xlabel('Elapsed (min)'); title('Multisensor T / RH (in box)');

savefig_(f, fullfile(cfg.paths.figures,'03_science'), cfg);
end

function savefig_(f, base, cfg)
for k=1:numel(cfg.plot.export_formats)
    exportgraphics(f,[base,'.',cfg.plot.export_formats{k}],'Resolution',cfg.plot.dpi);
end
fprintf('  saved -> %s\n', base);
end
