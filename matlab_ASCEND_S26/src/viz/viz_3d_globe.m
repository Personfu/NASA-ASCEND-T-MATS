function f = viz_3d_globe(D, cfg)
%VIZ_3D_GLOBE  3-D Earth-relative flight path with WGS-84 ellipsoid.

T = D.trajectory;
co = cfg.plot.colors;

a = cfg.wgs84.a; b_e = cfg.wgs84.b;
% Local ENU origin at launch
[xL,yL,zL] = lla2ecef(cfg.mission.launch_lat, cfg.mission.launch_lon, cfg.mission.launch_alt_m, a, b_e);
[xT,yT,zT] = lla2ecef(T.lat, T.lon, T.alt_m, a, b_e);
[E,N,U]   = ecef2enu(xT,yT,zT, xL,yL,zL, cfg.mission.launch_lat, cfg.mission.launch_lon);

f = figure('Name','ASCEND-S26 3D Globe','Color','w','Position',[80 80 1100 900]);
ax = axes(f);
[~,iA] = max(T.alt_m);

% Draw a ground square 30km x 30km centered on launch
extent = 50e3;
[Xg,Yg] = meshgrid(linspace(-extent,extent,40), linspace(-extent,extent,40));
Zg = zeros(size(Xg));
surf(ax, Xg/1000, Yg/1000, Zg/1000, 'FaceColor',[0.85 0.78 0.65], 'EdgeColor',[0.7 0.65 0.55],'FaceAlpha',0.6); hold on;

% Trajectory in ENU (km)
isAsc = T.phase=="ascent" | T.phase=="launch";
isDsc = T.phase=="descent" | T.phase=="landed";
plot3(ax, E(isAsc)/1000, N(isAsc)/1000, U(isAsc)/1000, '-','Color',co.ascent,'LineWidth',2);
plot3(ax, E(isDsc)/1000, N(isDsc)/1000, U(isDsc)/1000, '-','Color',co.descent,'LineWidth',2);

% Launch / burst / landing
plot3(0,0,0,'p','MarkerSize',16,'MarkerFaceColor','y','MarkerEdgeColor','k');
plot3(E(iA)/1000, N(iA)/1000, U(iA)/1000, 'o','MarkerSize',12,'MarkerFaceColor',co.burst,'MarkerEdgeColor','k');
plot3(E(end)/1000,N(end)/1000,U(end)/1000,'s','MarkerSize',12,'MarkerFaceColor','r','MarkerEdgeColor','k');

text(0,0,2,'Launch','FontWeight','bold');
text(E(iA)/1000, N(iA)/1000, U(iA)/1000+1, sprintf('Burst\n%.1f km',cfg.mission.burst_alt_m/1000), ...
    'FontWeight','bold','HorizontalAlignment','center');
text(E(end)/1000,N(end)/1000,U(end)/1000+1,'Landing','FontWeight','bold');

% Color the path by altitude
scatter3(ax, E/1000, N/1000, U/1000, 6, U/1000, 'filled','MarkerFaceAlpha',0.6);
cb = colorbar; cb.Label.String='Altitude AGL (km)';
colormap(ax,'turbo');

xlabel('East (km)'); ylabel('North (km)'); zlabel('Up AGL (km)');
title(sprintf('%s  -  3D ENU flight path  (origin: %.5f\\circN, %.5f\\circE)', ...
    cfg.mission.name, cfg.mission.launch_lat, cfg.mission.launch_lon));
grid on; axis equal vis3d; view(ax,-30,28);
camlight; lighting gouraud;

savefig_(f, fullfile(cfg.paths.figures,'07_3d_globe'), cfg);
end

function [x,y,z] = lla2ecef(lat,lon,h,a,b)
e2 = 1 - (b/a)^2;
phi = deg2rad(lat); lam = deg2rad(lon);
N = a ./ sqrt(1 - e2.*sin(phi).^2);
x = (N+h).*cos(phi).*cos(lam);
y = (N+h).*cos(phi).*sin(lam);
z = (N.*(1-e2)+h).*sin(phi);
end

function [E,N,U] = ecef2enu(x,y,z, x0,y0,z0, lat0,lon0)
phi = deg2rad(lat0); lam = deg2rad(lon0);
dx = x-x0; dy = y-y0; dz = z-z0;
E =  -sin(lam).*dx + cos(lam).*dy;
N =  -sin(phi).*cos(lam).*dx - sin(phi).*sin(lam).*dy + cos(phi).*dz;
U =   cos(phi).*cos(lam).*dx + cos(phi).*sin(lam).*dy + sin(phi).*dz;
end

function savefig_(f, base, cfg)
for k=1:numel(cfg.plot.export_formats)
    exportgraphics(f,[base,'.',cfg.plot.export_formats{k}],'Resolution',cfg.plot.dpi);
end
fprintf('  saved -> %s\n', base);
end
