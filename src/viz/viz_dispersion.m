function fig = viz_dispersion(MC, cfg)
%VIZ_DISPERSION  Monte Carlo landing dispersion ellipse.

fig = figure('Name','Landing Dispersion','Color','w','Position',[120 120 900 800]);
hold on; grid on; axis equal
scatter(MC.land_km(:,1), MC.land_km(:,2), 16, MC.impact_ms,'filled');
cb = colorbar; cb.Label.String = 'Impact speed (m/s)';

% Mean and CEPs
plot(MC.mean_km(1), MC.mean_km(2),'k+','MarkerSize',16,'LineWidth',2);
th = linspace(0,2*pi,200);
for r = [MC.cep50_km, MC.cep95_km]
    plot(MC.mean_km(1)+r*cos(th), MC.mean_km(2)+r*sin(th),'k--','LineWidth',1);
end

% 1-sigma covariance ellipse
[V_,D_] = eig(MC.cov_km2);
xy = (V_*sqrt(D_))*[cos(th); sin(th)];
plot(MC.mean_km(1)+xy(1,:), MC.mean_km(2)+xy(2,:),'r','LineWidth',1.5);

xlabel('East offset (km from launch)');
ylabel('North offset (km from launch)');
title(sprintf('Spring 2026 Landing Dispersion (N=%d)\nCEP_{50}=%.2f km   CEP_{95}=%.2f km', ...
    MC.N, MC.cep50_km, MC.cep95_km));
legend({'Trial','Mean','CEP50/95','1\sigma cov'},'Location','best');
exportgraphics(fig, fullfile(cfg.paths.figs,'dispersion.png'),'Resolution',cfg.viz.dpi);
end
