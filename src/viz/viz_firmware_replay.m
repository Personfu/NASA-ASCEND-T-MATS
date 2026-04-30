function fig = viz_firmware_replay(T, cfg)
%VIZ_FIRMWARE_REPLAY  Telemetry replay dashboard for HailMaryV1f logs.
%
%   FIG = VIZ_FIRMWARE_REPLAY(T) takes the timetable returned by either
%   FIRMWARE_DECODE_CSV or FIRMWARE_SIMULATE_FLIGHT and renders the
%   "what was the flight computer thinking?" dashboard:
%
%     1. Altitude (BMP) + flight phase shading
%     2. Vertical velocity + impact threshold
%     3. Acceleration magnitude with 15 g detector line
%     4. UV totals from each AS7331 sensor
%     5. Sensor health bitmask trace (rasterised)
%     6. Stale-data + free-RAM trace
%
%   Saves PNG/PDF to figures/ when cfg.figdir is provided.

if nargin < 2 || ~isstruct(cfg), cfg = struct('figdir',''); end
if ~isfield(cfg,'figdir'), cfg.figdir = ''; end

t = seconds(T.Properties.RowTimes);

fig = figure('Name','HailMaryV1f telemetry replay','Color','w', ...
             'Position',[80 60 1280 900]);
tl = tiledlayout(fig, 3, 2, 'TileSpacing','compact','Padding','compact');
title(tl,'HailMaryV1f Telemetry Replay');

% (1) altitude + phase shading
ax1 = nexttile(tl, 1);
plot(ax1, t, T.alt_m, 'LineWidth', 1.5); hold(ax1,'on');
phaseColor = [0.85 0.85 0.85; 0.80 0.92 1.00; 0.78 1.00 0.84;
              1.00 0.85 0.78; 1.00 0.78 0.78];
ph = double(T.phase);
boundaries = [1; find(diff(ph)~=0)+1; numel(ph)+1];
for k = 1:numel(boundaries)-1
    i1 = boundaries(k); i2 = boundaries(k+1)-1;
    p = ph(i1) + 1;
    if p<1, p=1; end; if p>5, p=5; end
    yl = ylim(ax1);
    patch(ax1, [t(i1) t(i2) t(i2) t(i1)], [yl(1) yl(1) yl(2) yl(2)], ...
          phaseColor(p,:), 'EdgeColor','none','FaceAlpha',0.35, ...
          'HandleVisibility','off');
end
plot(ax1, t, T.alt_m, 'LineWidth', 1.5, 'Color', [0.10 0.30 0.85]);
xlabel(ax1,'Elapsed (s)'); ylabel(ax1,'Altitude (m)');
title(ax1,'Altitude + Flight Phase'); grid(ax1,'on');

% (2) vertical velocity
ax2 = nexttile(tl, 2);
plot(ax2, t, T.vert_vel_mps, 'LineWidth', 1.0, 'Color',[0.20 0.55 0.20]);
yline(ax2, 0, '--k');
xlabel(ax2,'Elapsed (s)'); ylabel(ax2,'Vertical velocity (m/s)');
title(ax2,'Vertical Velocity (per-row d alt / dt)'); grid(ax2,'on');

% (3) accel magnitude + 15g line
ax3 = nexttile(tl, 3);
plot(ax3, t, T.accel_mag_mps2, 'LineWidth', 1.0, 'Color',[0.85 0.30 0.20]);
hold(ax3,'on');
yline(ax3, 147.0, '--', '15 g impact armed during DESCENT', ...
      'Color',[0.6 0 0],'LabelHorizontalAlignment','left');
xlabel(ax3,'Elapsed (s)'); ylabel(ax3,'|a| (m/s^2)');
title(ax3,'Acceleration Magnitude'); grid(ax3,'on');

% (4) UV totals
ax4 = nexttile(tl, 4);
uv1 = T.UV1A + T.UV1B + T.UV1C;
uv2 = T.UV2A + T.UV2B + T.UV2C;
uv3 = T.UV3A + T.UV3B + T.UV3C;
uv4 = T.UV4A + T.UV4B + T.UV4C;
plot(ax4, t, [uv1 uv2 uv3 uv4], 'LineWidth', 1.0);
xlabel(ax4,'Elapsed (s)'); ylabel(ax4,'UV total (uW/cm^2)');
legend(ax4,{'AS7331@0x74','AS7331@0x75','AS7331@0x76','AS7331@0x77'}, ...
       'Location','northwest','FontSize',8);
title(ax4,'UV Totals (A+B+C)'); grid(ax4,'on');

% (5) sensor health bitmask raster
ax5 = nexttile(tl, 5);
H = double([T.h_UV1 T.h_UV2 T.h_UV3 T.h_UV4 T.h_BMP T.h_BNO T.h_SD T.h_GPS]).';
imagesc(ax5, t, 1:8, H);
set(ax5,'YTick',1:8,'YTickLabel',{'UV1','UV2','UV3','UV4','BMP','BNO','SD','GPS'});
colormap(ax5, [0.85 0.20 0.20; 0.20 0.65 0.30]);
caxis(ax5,[0 1]); xlabel(ax5,'Elapsed (s)');
title(ax5,'Sensor Health Bitmask'); set(ax5,'YDir','reverse');

% (6) stale + free RAM
ax6 = nexttile(tl, 6); yyaxis(ax6,'left');
plot(ax6, t, T.stale_bmp, 'LineWidth',1.0); hold(ax6,'on');
plot(ax6, t, T.stale_bno, 'LineWidth',1.0);
ylabel(ax6,'Stale streak (samples)');
yyaxis(ax6,'right');
plot(ax6, t, T.free_ram, 'LineWidth',1.0,'Color',[0.40 0.10 0.55]);
ylabel(ax6,'Free SRAM (bytes)');
xlabel(ax6,'Elapsed (s)');
legend(ax6,{'stale BMP','stale BNO','free RAM'},'Location','northwest','FontSize',8);
title(ax6,'Staleness + Memory'); grid(ax6,'on');

if ~isempty(cfg.figdir)
    if ~isfolder(cfg.figdir), mkdir(cfg.figdir); end
    exportgraphics(fig, fullfile(cfg.figdir,'22_firmware_replay.png'),'Resolution',180);
    exportgraphics(fig, fullfile(cfg.figdir,'22_firmware_replay.pdf'));
end
end
