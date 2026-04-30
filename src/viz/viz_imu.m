function f = viz_imu(D, cfg)
%VIZ_IMU  9-DOF IMU + magnetometer dashboard from arduino log.

A = D.arduino;
co = cfg.plot.colors;

f = figure('Name','ASCEND-S26 IMU & Magnetometer','Color','w','Position',[80 80 1500 950]);
tlay = tiledlayout(f,3,2,'TileSpacing','compact','Padding','compact');
title(tlay,'Inertial / Magnetic Telemetry  -  ICM-20948 + LIS3MDL stack','FontWeight','bold','FontSize',13);

ax = nexttile;
plot(ax, A.t_s/60, A.gyro_x_dps, '-','Color',[0.85 0.30 0.10]); hold on;
plot(ax, A.t_s/60, A.gyro_y_dps, '-','Color',[0.30 0.85 0.30]);
plot(ax, A.t_s/60, A.gyro_z_dps, '-','Color',[0.10 0.30 0.85]);
grid on; xlabel('t (min)'); ylabel('\omega (deg/s)'); title('Gyroscope');
legend({'X','Y','Z'},'Location','best');

ax = nexttile;
plot(ax, A.t_s/60, A.accel_x_ms2, '-','Color',[0.85 0.30 0.10]); hold on;
plot(ax, A.t_s/60, A.accel_y_ms2, '-','Color',[0.30 0.85 0.30]);
plot(ax, A.t_s/60, A.accel_z_ms2, '-','Color',[0.10 0.30 0.85]);
plot(ax, A.t_s/60, A.accel_total_ms2, '-k','LineWidth',1.2);
grid on; xlabel('t (min)'); ylabel('a (m/s^2)'); title('Accelerometer');
legend({'X','Y','Z','|a|'},'Location','best');

ax = nexttile;
plot(ax, A.t_s/60, A.accel_total_g, '-','Color',[0.55 0.10 0.55],'LineWidth',1.0);
grid on; xlabel('t (min)'); ylabel('|a| (g)'); title('Spin-up / shock loading (g)');

ax = nexttile;
plot(ax, A.t_s/60, A.mag_x_uT, '-','Color',[0.10 0.30 0.55]); hold on;
plot(ax, A.t_s/60, A.mag_y_uT, '-','Color',[0.30 0.55 0.30]);
plot(ax, A.t_s/60, A.mag_z_uT, '-','Color',[0.55 0.30 0.10]);
grid on; xlabel('t (min)'); ylabel('B (\muT)'); title('Magnetometer');
legend({'X','Y','Z'},'Location','best');

% 3D gyro/mag scatter for spin signature
ax = nexttile;
scatter3(ax, A.gyro_x_dps, A.gyro_y_dps, A.gyro_z_dps, 6, A.t_s, 'filled');
xlabel('\omega_X'); ylabel('\omega_Y'); zlabel('\omega_Z');
cb = colorbar; cb.Label.String='t (s)'; colormap(ax,'turbo');
grid on; title('Angular rate phase space');

% Mag sphere
ax = nexttile;
scatter3(ax, A.mag_x_uT, A.mag_y_uT, A.mag_z_uT, 4, A.t_s, 'filled');
xlabel('B_X'); ylabel('B_Y'); zlabel('B_Z');
title('Magnetometer 3-D locus (calibration sphere)');
grid on; axis equal;

savefig_(f, fullfile(cfg.paths.figures,'04_imu'), cfg);
end

function savefig_(f, base, cfg)
for k=1:numel(cfg.plot.export_formats)
    exportgraphics(f,[base,'.',cfg.plot.export_formats{k}],'Resolution',cfg.plot.dpi);
end
fprintf('  saved -> %s\n', base);
end
