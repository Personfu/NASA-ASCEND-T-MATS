function fig = viz_payload_dynamics(T, cfg)
%VIZ_PAYLOAD_DYNAMICS  Fundamental + advanced 6-DOF dynamics dashboard.
%
%   FIG = VIZ_PAYLOAD_DYNAMICS(T) takes a HailMaryV1f telemetry timetable
%   and computes textbook payload dynamics quantities:
%
%       * tilt angle from gravity vector (atan2 of x-y vs z accel)
%       * angular speed |omega| from gyro vector
%       * spin energy 0.5 * I * omega^2 with payload inertia from PE
%       * Madgwick-style complementary attitude filter (roll/pitch)
%       * angular momentum stem trace
%
%   This is the "Fundamental + Advanced" engineering content for the
%   payload: real classical-mechanics quantities computed from on-board
%   IMU data, not synthetic show pieces.

if nargin < 2 || ~isstruct(cfg), cfg = struct('figdir',''); end
if ~isfield(cfg,'figdir'), cfg.figdir = ''; end

t  = seconds(T.Properties.RowTimes);
ax = T.accelX; ay = T.accelY; az = T.accelZ;
gx = deg2rad(T.gyroX); gy = deg2rad(T.gyroY); gz = deg2rad(T.gyroZ);

% Tilt from gravity vector
tilt_deg = rad2deg(atan2(sqrt(ax.^2+ay.^2), az));

% Magnitude of angular velocity
omega = sqrt(gx.^2 + gy.^2 + gz.^2);

% Payload inertia from engineering record
try
    PE = payload_engineering();
    Ixyz = PE.totals.inertia_kgm2;       % 3x1
catch
    Ixyz = [0.012; 0.012; 0.005];        % conservative fallback
end
Ibar = mean(Ixyz);
Espin = 0.5 * Ibar * omega.^2;
Lmag  = Ibar * omega;

% Complementary filter: integrate gyro, fuse with accel-derived tilt
roll = zeros(size(t)); pitch = zeros(size(t));
alpha = 0.98;
for i = 2:numel(t)
    dt = t(i) - t(i-1); if dt<=0 || dt>1, dt = 0.5; end
    roll_acc  = atan2(ay(i), az(i));
    pitch_acc = atan2(-ax(i), sqrt(ay(i).^2 + az(i).^2));
    roll(i)  = alpha*(roll(i-1)  + gx(i)*dt) + (1-alpha)*roll_acc;
    pitch(i) = alpha*(pitch(i-1) + gy(i)*dt) + (1-alpha)*pitch_acc;
end

fig = figure('Name','Payload Dynamics','Color','w','Position',[80 60 1280 900]);
tl  = tiledlayout(fig,3,2,'TileSpacing','compact','Padding','compact');
title(tl,'Phoenix-1 Payload Dynamics — Fundamentals + Advanced');

ax1 = nexttile(tl,1);
plot(ax1, t, tilt_deg, 'LineWidth',1.0); grid(ax1,'on');
xlabel(ax1,'Elapsed (s)'); ylabel(ax1,'Tilt from gravity (deg)');
title(ax1,'Tilt vs Vertical (atan2 |a_{xy}|, a_z)');

ax2 = nexttile(tl,2);
plot(ax2, t, rad2deg(omega), 'LineWidth',1.0); grid(ax2,'on');
xlabel(ax2,'Elapsed (s)'); ylabel(ax2,'|\omega| (deg/s)');
title(ax2,'Angular Speed Magnitude');

ax3 = nexttile(tl,3);
plot(ax3, t, Espin, 'LineWidth',1.0); grid(ax3,'on');
xlabel(ax3,'Elapsed (s)'); ylabel(ax3,'Spin energy (J)');
title(ax3, sprintf('Rotational KE  (\\bar{I} = %.4g kg m^2)', Ibar));

ax4 = nexttile(tl,4);
plot(ax4, t, Lmag, 'LineWidth',1.0); grid(ax4,'on');
xlabel(ax4,'Elapsed (s)'); ylabel(ax4,'|L| (kg m^2 / s)');
title(ax4,'Angular Momentum Magnitude');

ax5 = nexttile(tl,5);
plot(ax5, t, rad2deg(roll), t, rad2deg(pitch), 'LineWidth',1.0); grid(ax5,'on');
legend(ax5,{'roll','pitch'},'Location','best');
xlabel(ax5,'Elapsed (s)'); ylabel(ax5,'Attitude (deg)');
title(ax5,'Complementary Filter Attitude (\alpha = 0.98)');

ax6 = nexttile(tl,6);
% Phase-plane: roll vs roll-rate
plot(ax6, rad2deg(roll), rad2deg(gx), 'LineWidth',0.6); grid(ax6,'on');
xlabel(ax6,'Roll (deg)'); ylabel(ax6,'Roll rate (deg/s)');
title(ax6,'Phase-plane: Roll vs Roll-rate');

if ~isempty(cfg.figdir)
    if ~isfolder(cfg.figdir), mkdir(cfg.figdir); end
    exportgraphics(fig, fullfile(cfg.figdir,'23_payload_dynamics.png'),'Resolution',180);
    exportgraphics(fig, fullfile(cfg.figdir,'23_payload_dynamics.pdf'));
end
end
