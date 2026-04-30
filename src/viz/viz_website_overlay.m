function viz_website_overlay(D, cfg)
%VIZ_WEBSITE_OVERLAY  Compare website public-release telemetry with
%   raw multisensor / arduino ingestion: UV total, radiation, IMU.
%
%   Output: figures/13_website_overlay.png|pdf

f = figure('Color','w','Position',[60 60 1500 950],'Name','Website overlay');
tl = tiledlayout(f,2,2,'TileSpacing','compact','Padding','compact');

% ---- UV total ----------------------------------------------------
ax = nexttile; hold(ax,'on'); grid(ax,'on'); box(ax,'on');
if isfield(D,'web_payload') && height(D.web_payload)>0
    plot(ax, D.web_payload.alt_ft, D.web_payload.uv_total, '.', ...
         'Color',[0.55 0.10 0.65],'MarkerSize',6, 'DisplayName','website UV total');
end
if isfield(D,'web_imu') && isfield(D.web_imu,'tt') && height(D.web_imu.tt)>0
    plot(ax, D.web_imu.tt.alt_ft, D.web_imu.tt.uv_total, 'o', ...
         'Color',[0.10 0.45 0.85],'MarkerSize',4, 'DisplayName','public IMU UV');
end
xlabel(ax,'altitude (ft)'); ylabel(ax,'UV total (counts)');
title(ax,'UV photometric truth','FontWeight','bold'); legend(ax,'Location','best');

% ---- radiation ---------------------------------------------------
ax = nexttile; hold(ax,'on'); grid(ax,'on'); box(ax,'on');
if isfield(D,'web_radiation') && isfield(D.web_radiation,'tt') && height(D.web_radiation.tt)>0
    R = D.web_radiation.tt;
    yyaxis left
    plot(ax, R.alt_ft, R.cpm, '-', 'Color',[0.85 0.10 0.45], ...
         'LineWidth',1.3, 'DisplayName','CPM');
    ylabel(ax,'CPM');
    yyaxis right
    plot(ax, R.alt_ft, R.usv_h, '--', 'Color',[0.40 0.10 0.20], ...
         'LineWidth',1.0, 'DisplayName','\muSv/h');
    ylabel(ax,'dose rate (\muSv/h)');
    if isfield(cfg.truth,'pfotzer_alt_ft')
        xline(ax, cfg.truth.pfotzer_alt_ft, ':k','Pfotzer-Regener','LabelOrientation','horizontal');
    end
end
xlabel(ax,'altitude (ft)');
title(ax,'Cosmic-ray vs altitude (public release)','FontWeight','bold');

% ---- g-load ------------------------------------------------------
ax = nexttile; hold(ax,'on'); grid(ax,'on'); box(ax,'on');
if isfield(D,'web_imu') && isfield(D.web_imu,'tt') && height(D.web_imu.tt)>0
    I = D.web_imu.tt;
    plot(ax, I.elapsed_s/60, I.g_load, '-', 'Color',[0.10 0.45 0.85], ...
         'LineWidth',1.2,'DisplayName','|g| public');
    yline(ax, 1.0, ':k','1 g static');
    if isfield(cfg.truth,'max_g_load')
        yline(ax, cfg.truth.max_g_load, '--r', ...
            sprintf('peak %.2f g',cfg.truth.max_g_load));
    end
end
xlabel(ax,'time (min)'); ylabel(ax,'|g|');
title(ax,'IMU g-load record (public)','FontWeight','bold');

% ---- pressure / temp ---------------------------------------------
ax = nexttile; hold(ax,'on'); grid(ax,'on'); box(ax,'on');
if isfield(D,'web_payload') && height(D.web_payload)>0
    yyaxis left
    plot(ax, D.web_payload.alt_ft, D.web_payload.pressure_pa/100, '-', ...
        'Color',[0.10 0.45 0.85],'DisplayName','pressure (hPa)');
    ylabel(ax,'pressure (hPa)'); set(ax,'YScale','log');
    yyaxis right
    plot(ax, D.web_payload.alt_ft, D.web_payload.temp_c, '-', ...
        'Color',[0.95 0.30 0.10],'DisplayName','temp (\circC)');
    ylabel(ax,'temperature (\circC)');
end
xlabel(ax,'altitude (ft)');
title(ax,'BMP390 pressure & temperature (website)','FontWeight','bold');

title(tl, sprintf('%s  -  Website public-release overlay', cfg.mission.name), ...
      'FontWeight','bold','FontSize',13);

out = fullfile(cfg.paths.figures,'13_website_overlay');
exportgraphics(f,[out '.png'],'Resolution',cfg.plot.dpi);
exportgraphics(f,[out '.pdf'],'ContentType','vector');
fprintf('  viz_website_overlay -> %s.{png,pdf}\n', out);
end
