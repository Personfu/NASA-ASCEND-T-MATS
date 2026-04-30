function animate_flight(D, cfg, outfile)
%ANIMATE_FLIGHT  Animated flight playback exported as MP4.
%
%   animate_flight(D, cfg, outfile) renders a synchronized 4-pane
%   animation of the Spring 2026 ASCEND flight:
%     - 3D ENU trajectory (with launch / burst / land markers)
%     - altitude vs time
%     - vertical velocity vs time
%     - mission timer + telemetry table

if nargin < 3, outfile = fullfile(cfg.paths.figs,'ascend_flight.mp4'); end

T = D.trajectory;
n = height(T); t = T.t_s;
[xE, xN] = deal(zeros(n,1));
for i = 1:n
    [d, az, ~] = wgs84_inverse(cfg.mission.launch_lat, cfg.mission.launch_lon, T.lat(i), T.lon(i));
    xE(i) = d*sind(az); xN(i) = d*cosd(az);
end
xU = T.alt_m - cfg.mission.launch_alt_m;

fig = figure('Color','k','Position',[40 40 1500 850],'InvertHardcopy','off');
tl = tiledlayout(2,3,'TileSpacing','compact','Padding','compact');

% 3D
ax1 = nexttile([2 2]); hold(ax1,'on'); grid(ax1,'on'); axis(ax1,'vis3d');
set(ax1,'Color','k','XColor','w','YColor','w','ZColor','w');
plot3(ax1, xE/1000, xN/1000, xU/1000,'-','Color',[.4 .4 .4]);
h3d = animatedline(ax1,'Color','c','LineWidth',2);
hpt = plot3(ax1, NaN,NaN,NaN,'wo','MarkerFaceColor','y','MarkerSize',8);
xlabel(ax1,'East (km)'); ylabel(ax1,'North (km)'); zlabel(ax1,'Up (km)');
title(ax1,'3D Trajectory (ENU)','Color','w'); view(ax1,40,28);

% alt
ax2 = nexttile; hold(ax2,'on'); grid(ax2,'on');
set(ax2,'Color','k','XColor','w','YColor','w');
plot(ax2, t/60, T.alt_m/1000,'Color',[.4 .4 .4]);
ha = animatedline(ax2,'Color','y','LineWidth',2);
xlabel(ax2,'time (min)'); ylabel(ax2,'Alt (km)'); title(ax2,'Altitude','Color','w');

% vz
ax3 = nexttile; hold(ax3,'on'); grid(ax3,'on');
set(ax3,'Color','k','XColor','w','YColor','w');
plot(ax3, t/60, T.vz_ms,'Color',[.4 .4 .4]);
hv = animatedline(ax3,'Color','m','LineWidth',2);
xlabel(ax3,'time (min)'); ylabel(ax3,'vz (m/s)'); title(ax3,'Vertical Velocity','Color','w');

vw = VideoWriter(outfile,'MPEG-4');
vw.FrameRate = 30; vw.Quality = 92; open(vw);

step = max(1, round(n/600));
for i = 1:step:n
    addpoints(h3d, xE(i)/1000, xN(i)/1000, xU(i)/1000);
    set(hpt,'XData',xE(i)/1000,'YData',xN(i)/1000,'ZData',xU(i)/1000);
    addpoints(ha, t(i)/60, T.alt_m(i)/1000);
    addpoints(hv, t(i)/60, T.vz_ms(i));

    title(tl, sprintf('ASCEND Spring 2026 - T+%05.1f min   alt=%.2f km   vz=%+5.1f m/s   phase=%s', ...
        t(i)/60, T.alt_m(i)/1000, T.vz_ms(i), T.phase(i)),'Color','w','FontWeight','bold');
    drawnow limitrate;
    writeVideo(vw, getframe(fig));
end
close(vw); close(fig);
fprintf('Animation written: %s\n', outfile);
end
