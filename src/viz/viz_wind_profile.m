function fig = viz_wind_profile(W, cfg)
%VIZ_WIND_PROFILE  Hodograph + altitude profile of derived winds.

fig = figure('Name','Wind Profile','Color','w','Position',[100 100 1300 700]);
tl = tiledlayout(1,3,'TileSpacing','compact','Padding','compact');

% Altitude profile
nexttile; plot(W.spd_ms, W.h_m/1000,'LineWidth',1.6); grid on
xlabel('Wind speed (m/s)'); ylabel('Altitude (km)'); title('|V| vs h');

% Direction profile
nexttile; plot(W.dir_from_deg, W.h_m/1000,'LineWidth',1.6); grid on
xlabel('Wind direction "from" (\circ)'); ylabel('Altitude (km)'); title('Direction vs h');
xlim([0 360]); xticks(0:45:360);

% Hodograph
nexttile; hold on; grid on; axis equal
cmap = parula(numel(W.h_m));
for i = 1:numel(W.h_m)-1
    plot([W.U_ms(i) W.U_ms(i+1)],[W.V_ms(i) W.V_ms(i+1)], ...
         'Color',cmap(i,:),'LineWidth',1.5);
end
scatter(W.U_ms, W.V_ms, 18, W.h_m/1000,'filled');
cb = colorbar; cb.Label.String='Altitude (km)';
xlabel('U east (m/s)'); ylabel('V north (m/s)');
title('Hodograph');

title(tl, 'Spring 2026 Wind Profile (data-derived)','FontWeight','bold');
exportgraphics(fig, fullfile(cfg.paths.figs,'wind_profile.png'),'Resolution',cfg.viz.dpi);
end
