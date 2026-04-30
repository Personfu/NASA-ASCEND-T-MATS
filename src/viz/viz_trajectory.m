function f = viz_trajectory(D, cfg)
%VIZ_TRAJECTORY  Six-panel master trajectory dashboard.

T = D.trajectory;
W = D.wind;
co = cfg.plot.colors;

f = figure('Name','ASCEND-S26 Trajectory Dashboard','Color','w','Position',[60 60 1400 900]);
tlay = tiledlayout(f, 3,2, 'TileSpacing','compact','Padding','compact');
title(tlay, sprintf('%s  -  Balloon 2 (%s)  |  Launch %s UTC', ...
    cfg.mission.name, cfg.mission.aprs_callsign, datestr(cfg.mission.launch_time_utc,'yyyy-mm-dd HH:MM:SS')), ...
    'FontWeight','bold','FontSize',13);

% (1) Altitude vs time
ax1 = nexttile(tlay,1);
isAsc = T.phase=="ascent" | T.phase=="launch";
isDsc = T.phase=="descent" | T.phase=="landed";
plot(ax1, T.t_s(isAsc)/60, T.alt_ft(isAsc)/1000, '-', 'Color',co.ascent, 'LineWidth',1.6); hold(ax1,'on');
plot(ax1, T.t_s(isDsc)/60, T.alt_ft(isDsc)/1000, '-', 'Color',co.descent,'LineWidth',1.6);
[apex,iA] = max(T.alt_ft);
plot(ax1, T.t_s(iA)/60, apex/1000, 'o','MarkerFaceColor',co.burst,'MarkerEdgeColor','k','MarkerSize',9);
text(ax1, T.t_s(iA)/60, apex/1000, sprintf('  BURST  %.0f ft\n  %.1f km', apex, apex*0.3048/1000), ...
    'VerticalAlignment','bottom','FontWeight','bold');
grid(ax1,'on'); xlabel(ax1,'Elapsed time (min)'); ylabel(ax1,'Altitude (kft MSL)');
title(ax1,'Altitude profile'); legend(ax1,{'Ascent','Descent','Burst'},'Location','best');

% (2) Vertical velocity
ax2 = nexttile(tlay,2);
plot(ax2, T.t_s/60, T.vz_mph, '-', 'Color',[0.20 0.30 0.55], 'LineWidth',1.4); hold(ax2,'on');
yline(ax2, cfg.mission.peak_descent_mph*-1, '--r', sprintf('peak descent %.1f mph',cfg.mission.peak_descent_mph));
yline(ax2, 0,'-k');
grid(ax2,'on'); xlabel(ax2,'Elapsed time (min)'); ylabel(ax2,'Vertical speed (mph)');
title(ax2,'Vertical velocity (APRS-derived)');

% (3) Vertical accel
ax3 = nexttile(tlay,3);
plot(ax3, T.t_s/60, T.az_g, '-', 'Color',[0.55 0.10 0.55], 'LineWidth',1.2);
grid(ax3,'on'); xlabel(ax3,'Elapsed time (min)'); ylabel(ax3,'Vertical accel (g)');
title(ax3,'Vertical acceleration'); ylim(ax3,[-0.5 0.5]);

% (4) Wind / lateral speed
ax4 = nexttile(tlay,4);
plot(ax4, W.alt_m/1000, W.vlat_mph, '.', 'Color',co.gnd, 'MarkerSize',6); hold(ax4,'on');
[~,~,sm] = smooth_curve(W.alt_m, W.vlat_mph, 25);
plot(ax4, W.alt_m/1000, sm, '-', 'Color',[0.0 0.30 0.10], 'LineWidth',1.6);
grid(ax4,'on'); xlabel(ax4,'Altitude (km)'); ylabel(ax4,'Lateral wind speed (mph)');
title(ax4,'Lateral wind vs altitude (Vincenty inverse)');
legend(ax4,{'Per-fix','Moving avg (25)'},'Location','best');

% (5) 3D ground track w/ altitude colormap
ax5 = nexttile(tlay,5);
scatter3(ax5, T.lon, T.lat, T.alt_m/1000, 14, T.alt_m/1000, 'filled');
hold(ax5,'on');
plot3(ax5, cfg.mission.launch_lon, cfg.mission.launch_lat, cfg.mission.launch_alt_m/1000, ...
    'p','MarkerSize',12,'MarkerFaceColor','y','MarkerEdgeColor','k');
plot3(ax5, T.lon(end), T.lat(end), T.alt_m(end)/1000, 's','MarkerFaceColor','r','MarkerEdgeColor','k','MarkerSize',9);
xlabel(ax5,'Longitude (\circE)'); ylabel(ax5,'Latitude (\circN)'); zlabel(ax5,'Altitude (km)');
cb = colorbar(ax5); cb.Label.String = 'Altitude (km)'; colormap(ax5,'turbo');
grid(ax5,'on'); title(ax5,'3D flight path (WGS-84)');
view(ax5,-35,28);

% (6) Ground track 2D
ax6 = nexttile(tlay,6);
plot(ax6, T.lon, T.lat, '-', 'Color',[0.10 0.10 0.10], 'LineWidth',1.4); hold(ax6,'on');
isAscPath = T.phase=="ascent"; isDscPath = T.phase=="descent";
plot(ax6, T.lon(isAscPath), T.lat(isAscPath), '.','Color',co.ascent,'MarkerSize',8);
plot(ax6, T.lon(isDscPath), T.lat(isDscPath), '.','Color',co.descent,'MarkerSize',8);
plot(ax6, cfg.mission.launch_lon, cfg.mission.launch_lat, 'p','MarkerSize',16,'MarkerFaceColor','y','MarkerEdgeColor','k');
plot(ax6, T.lon(iA), T.lat(iA), 'o','MarkerSize',12,'MarkerFaceColor',co.burst,'MarkerEdgeColor','k');
plot(ax6, T.lon(end), T.lat(end), 's','MarkerSize',12,'MarkerFaceColor','r','MarkerEdgeColor','k');
grid(ax6,'on'); axis(ax6,'equal');
xlabel(ax6,'Longitude'); ylabel(ax6,'Latitude'); title(ax6,'Ground track');
legend(ax6,{'Track','Ascent fixes','Descent fixes','Launch','Burst','Landing'},'Location','best','FontSize',8);

savefig_(f, fullfile(cfg.paths.figures,'01_trajectory_dashboard'), cfg);
end

function [xs,ys,ysm] = smooth_curve(x,y,w)
[xs,o]=sort(x); ys=y(o); ysm=movmean(ys,w,'omitnan');
end

function savefig_(f, base, cfg)
for k=1:numel(cfg.plot.export_formats)
    fmt = cfg.plot.export_formats{k};
    exportgraphics(f, [base,'.',fmt], 'Resolution', cfg.plot.dpi);
end
fprintf('  saved -> %s.{%s}\n', base, strjoin(cfg.plot.export_formats,','));
end
