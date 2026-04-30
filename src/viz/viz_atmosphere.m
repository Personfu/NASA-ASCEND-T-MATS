function f = viz_atmosphere(D, cfg)
%VIZ_ATMOSPHERE  US-1976 standard atmosphere overlaid with flight data.

co = cfg.plot.colors;
h = (0:100:35000)';
[T,P,rho,a,mu,nu] = atm_us1976(h);

A = D.arduino;
M = D.multi;

f = figure('Name','ASCEND-S26 Atmosphere','Color','w','Position',[80 80 1400 850]);
tlay = tiledlayout(f,2,3,'TileSpacing','compact','Padding','compact');
title(tlay,'U.S. Standard Atmosphere 1976  vs  Flight Sensors','FontWeight','bold','FontSize',13);

ax = nexttile; plot(T-273.15,h/1000,'-','Color',co.thermal,'LineWidth',1.6); hold on;
if any(~isnan(A.temp_C))
    h_a = A.alt_baro_m; 
    scatter(A.temp_C, h_a/1000, 6, [0.2 0.3 0.55],'filled','MarkerFaceAlpha',0.4);
end
grid on; xlabel('Temperature (\circC)'); ylabel('Altitude (km)'); title('Temperature');
legend({'US-1976','BMP390'},'Location','best');

ax = nexttile; semilogx(P,h/1000,'-','Color',co.descent,'LineWidth',1.6); hold on;
if any(~isnan(A.press_Pa))
    scatter(A.press_Pa, A.alt_baro_m/1000, 6, [0.55 0.20 0.10],'filled','MarkerFaceAlpha',0.4);
end
grid on; xlabel('Pressure (Pa)'); ylabel('Altitude (km)'); title('Pressure');
legend({'US-1976','BMP390'},'Location','best');

ax = nexttile; semilogx(rho,h/1000,'-','Color',co.ascent,'LineWidth',1.6);
grid on; xlabel('Density (kg/m^3)'); ylabel('Altitude (km)'); title('Density');

ax = nexttile; plot(a,h/1000,'-','Color',[0.30 0.55 0.30],'LineWidth',1.6);
grid on; xlabel('Speed of sound (m/s)'); ylabel('Altitude (km)'); title('Acoustic speed');

ax = nexttile; plot(mu*1e5,h/1000,'-','Color',[0.55 0.30 0.10],'LineWidth',1.6);
grid on; xlabel('Dynamic viscosity (\times 10^{-5} Pa\cdots)'); ylabel('Altitude (km)'); title('\mu (Sutherland)');

ax = nexttile; semilogx(nu,h/1000,'-','Color',[0.10 0.45 0.55],'LineWidth',1.6);
grid on; xlabel('Kinematic viscosity (m^2/s)'); ylabel('Altitude (km)'); title('\nu = \mu/\rho');

savefig_(f, fullfile(cfg.paths.figures,'02_atmosphere'), cfg);
end

function savefig_(f, base, cfg)
for k=1:numel(cfg.plot.export_formats)
    exportgraphics(f, [base,'.',cfg.plot.export_formats{k}], 'Resolution', cfg.plot.dpi);
end
fprintf('  saved -> %s\n', base);
end
