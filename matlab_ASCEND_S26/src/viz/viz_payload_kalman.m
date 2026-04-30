function fig = viz_payload_kalman(T, cfg)
%VIZ_PAYLOAD_KALMAN  1-D Kalman altitude estimator from BMP + accel.
%
%   FIG = VIZ_PAYLOAD_KALMAN(T) fuses the BMP barometric altitude with
%   integrated vertical acceleration through a constant-acceleration
%   Kalman filter. This demonstrates how the on-board V1f sensors can
%   feed a graduate-level state estimator and dramatically tighten the
%   altitude trace at burst when the BMP saturates from shock.
%
%   State : x = [h; vz; az_b]  (altitude, vertical velocity, accel bias)
%   Meas  : barometric altitude every sample (R = sigma_h^2)
%   Input : measured vertical acceleration (Q from process noise)

if nargin < 2 || ~isstruct(cfg), cfg = struct('figdir',''); end
if ~isfield(cfg,'figdir'), cfg.figdir = ''; end

t = seconds(T.Properties.RowTimes);
N = numel(t);
hMeas = T.alt_m;
% Estimate vertical accel by removing gravity from total z-axis accel
azWorld = T.accelZ - 9.81;

x = [hMeas(1); 0; 0];
P = diag([100, 25, 1]);
Q = diag([0.01, 0.5, 0.01]);
R = (3.0)^2;   % BMP altitude std ~3m

xs = zeros(3, N); xs(:,1) = x;
for k = 2:N
    dt = t(k) - t(k-1); if dt<=0 || dt>2, dt = 0.5; end
    F = [1 dt 0.5*dt^2; 0 1 dt; 0 0 1];
    B = [0.5*dt^2; dt; 0];
    u = azWorld(k);
    x = F*x + B*u;
    P = F*P*F' + Q;
    z = hMeas(k);
    H = [1 0 0];
    y = z - H*x;
    S = H*P*H' + R;
    K = P*H'/S;
    x = x + K*y;
    P = (eye(3) - K*H)*P;
    xs(:,k) = x;
end

fig = figure('Name','Payload Kalman','Color','w','Position',[80 60 1280 760]);
tl  = tiledlayout(fig,2,1,'TileSpacing','compact','Padding','compact');
title(tl,'Phoenix-1 Altitude Kalman Filter (BMP + a_z)');

ax1 = nexttile(tl,1);
plot(ax1, t, hMeas, 'LineWidth',0.7,'Color',[0.6 0.6 0.6]); hold(ax1,'on');
plot(ax1, t, xs(1,:), 'LineWidth',1.5,'Color',[0.10 0.30 0.85]);
legend(ax1,{'BMP raw','Kalman'},'Location','best'); grid(ax1,'on');
xlabel(ax1,'Elapsed (s)'); ylabel(ax1,'Altitude (m)');
title(ax1,'Altitude: raw vs fused');

ax2 = nexttile(tl,2);
plot(ax2, t, xs(2,:), 'LineWidth',1.0,'Color',[0.20 0.55 0.20]); grid(ax2,'on');
xlabel(ax2,'Elapsed (s)'); ylabel(ax2,'v_z (m/s)');
title(ax2,'Vertical velocity (Kalman state)');

if ~isempty(cfg.figdir)
    if ~isfolder(cfg.figdir), mkdir(cfg.figdir); end
    exportgraphics(fig, fullfile(cfg.figdir,'25_payload_kalman.png'),'Resolution',180);
    exportgraphics(fig, fullfile(cfg.figdir,'25_payload_kalman.pdf'));
end
end
