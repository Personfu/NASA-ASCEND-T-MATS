function fig = viz_link_budget(L, cfg)
%VIZ_LINK_BUDGET  RF link budget dashboard.

fig = figure('Name','APRS Link Budget','Color','w','Position',[100 100 1300 800]);
tl = tiledlayout(2,3,'TileSpacing','compact','Padding','compact');

t = seconds(L.Properties.RowTimes);
nexttile; plot(t/60, L.alt_m/1000,'LineWidth',1.5); grid on
xlabel('time (min)'); ylabel('Altitude (km)'); title('Altitude');

nexttile; plot(L.d_km, L.alt_m/1000,'LineWidth',1.5); grid on
xlabel('Slant Range (km)'); ylabel('Altitude (km)'); title('Range vs Altitude');

nexttile; plot(t/60, L.fspl_dB,'LineWidth',1.5); grid on
xlabel('time (min)'); ylabel('FSPL (dB)'); title('Free-Space Path Loss');

nexttile; plot(t/60, L.prx_dBm,'LineWidth',1.5); grid on; hold on
yline(L.Properties.UserData.kTBW_dBm + L.Properties.UserData.SNRmin_dB,'r--','Threshold');
xlabel('time (min)'); ylabel('P_{rx} (dBm)'); title('Received Power');

nexttile; plot(t/60, L.snr_dB,'LineWidth',1.5); grid on; hold on
yline(L.Properties.UserData.SNRmin_dB,'r--','SNR_{min}');
xlabel('time (min)'); ylabel('SNR (dB)'); title('SNR (16 kHz BW)');

nexttile; plot(t/60, L.link_margin_dB,'LineWidth',1.5); grid on; hold on
yline(0,'r--','LOS');
xlabel('time (min)'); ylabel('Margin (dB)'); title('Link Margin');

title(tl, sprintf('APRS Link Budget @ %.3f MHz | GS [%.3f, %.3f]', ...
    L.Properties.UserData.f_MHz, L.Properties.UserData.gs.lat, ...
    L.Properties.UserData.gs.lon),'FontWeight','bold');
exportgraphics(fig, fullfile(cfg.paths.figs,'link_budget.png'),'Resolution',cfg.viz.dpi);
end
