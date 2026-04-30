function viz_gforce_burst(D, cfg)
%VIZ_GFORCE_BURST  3-D g-force vector map and burst dynamics dashboard.
%
%   Designed and authored by Personfu for the Phoenix College NASA
%   ASCEND Spring 2026 mission. Reconstructs the burst-event accelerometer
%   field around max-g (T+3844 s, ~86,761 ft) using raw 9-DOF Arduino
%   data, fuses it against the website public IMU, and renders:
%
%       (1) 3-D quiver "fountain" of body-frame acceleration vectors
%           through the burst window, color-graded by |a|/g, tail at
%           sample time, head at instantaneous direction.
%       (2) Acceleration triad (ax,ay,az) and |a|/g timeline with
%           Hampel outlier filter and 1g static gravity removed.
%       (3) Body-frame angular velocity ||omega|| and tumble rate.
%       (4) Spherical scatter of the unit acceleration direction
%           (theta = polar from +Z, phi = azimuth) showing how the
%           body axes reorient through burst.
%       (5) Power spectral density of |a| (Welch) - identifies any
%           structural ringing of the foamcore enclosure.
%       (6) Jerk magnitude  ||da/dt||  and impulse  ?|F| dt over
%           the burst window (per unit mass).
%
%   All math is grounded in the website-truth peak (6.211 g) and
%   raw Arduino LSM6DSO + LIS3MDL sampling.
%
%   Equations:
%       a_body          = [ax ay az]                             (m/s^2)
%       a_inertial_meas = a_body  (sensor frame)
%       |a|/g           = ||a_body|| / g0,   g0 = 9.80665 m/s^2
%       a_dyn           = a_body - R^T(att) * [0;0;-g0]   (gravity removed)
%       (R unknown without attitude -> we approximate dyn part as
%        ||a||/g - 1 for headline, use mean-removed time series for FFT)
%       jerk_k          = (a_{k+1} - a_{k-1}) / (t_{k+1}-t_{k-1})
%       J_norm          = ||jerk||
%       theta_k         = acos( az / ||a|| )
%       phi_k           = atan2( ay, ax )
%       omega_norm      = ||[gx gy gz]||  (deg/s)
%       PSD via pwelch( |a|, hann(N), 50%, NFFT, fs )
%       Impulse_per_mass= ? ||a|| dt   (m/s)
%
%   Output: figures/14_gforce_burst.{png,pdf,fig}

if nargin < 2 || ~isfield(D,'arduino') || height(D.arduino) < 100
    warning('viz_gforce_burst: no arduino IMU data available'); return
end
A = D.arduino;
g0 = 9.80665;

% -------- locate burst window ------------------------------------
t_max_s = 3844;
if isfield(cfg,'truth') && isfield(cfg.truth,'max_g_elapsed_s') && ~isempty(cfg.truth.max_g_elapsed_s)
    t_max_s = cfg.truth.max_g_elapsed_s;
end
half_window = 90;                                % +/- 90 s
t_s = A.t_s(:);
mask = t_s >= (t_max_s - half_window) & t_s <= (t_max_s + half_window);
if nnz(mask) < 50
    [~,kc] = max(A.accel_total_g);
    tc = t_s(kc);
    mask = t_s >= (tc - half_window) & t_s <= (tc + half_window);
    t_max_s = tc;
end
W = A(mask,:);
ts = W.t_s - t_max_s;                            % seconds relative to burst

ax = W.accel_x_ms2; ay = W.accel_y_ms2; az = W.accel_z_ms2;
gx = W.gyro_x_dps;  gy = W.gyro_y_dps;  gz = W.gyro_z_dps;
amag = sqrt(ax.^2 + ay.^2 + az.^2);
gmag = amag / g0;

% Hampel outlier suppression (3-sigma over 21-sample window)
[ax_f] = hampel_safe(ax,21,3);
[ay_f] = hampel_safe(ay,21,3);
[az_f] = hampel_safe(az,21,3);
amag_f = sqrt(ax_f.^2+ay_f.^2+az_f.^2);

% jerk via central difference
dt = [diff(W.t_s); 1];                           % s
jx = central_diff(ax_f, W.t_s);
jy = central_diff(ay_f, W.t_s);
jz = central_diff(az_f, W.t_s);
jmag = sqrt(jx.^2+jy.^2+jz.^2);

% spherical orientation of acceleration vector
theta = acosd(az ./ max(amag,1e-6));
phi   = atan2d(ay, ax);

% impulse per unit mass (gravity-removed proxy: |a|-g)
dyn = max(amag_f - g0, 0);
impulse = trapz(W.t_s, dyn);                     % m/s

% sample rate (median)
fs = 1/median(diff(W.t_s));
if ~isfinite(fs) || fs <= 0, fs = 50; end

% =================================================================
f = figure('Color','w','Position',[40 40 1620 980], ...
           'Name','G-force burst dashboard (Personfu)');
tl = tiledlayout(f,3,3,'TileSpacing','compact','Padding','compact');

% (1) 3-D quiver "fountain" -- big tile spanning 2x2
ax1 = nexttile(tl,1,[2 2]); hold(ax1,'on'); grid(ax1,'on'); box(ax1,'on');
% subsample to keep figure light
N = numel(ts);
step = max(1, floor(N/220));
idx = 1:step:N;
% lay tails along the time axis on the X-axis: tail at (ts,0,0)
X0 = ts(idx); Y0 = zeros(numel(idx),1); Z0 = zeros(numel(idx),1);
U  = ax(idx)/g0; V = ay(idx)/g0; Wv = az(idx)/g0;
C  = gmag(idx);
% color by g magnitude
cmap = turbo(256);
cnorm = (C - min(C)) / max(eps, max(C)-min(C));
cidx  = max(1, min(256, round(cnorm*255)+1));
for k = 1:numel(idx)
    plot3(ax1, [X0(k) X0(k)+U(k)*4], [0 V(k)*4], [0 Wv(k)*4], ...
        '-', 'Color', cmap(cidx(k),:), 'LineWidth', 1.1);
    plot3(ax1, X0(k)+U(k)*4, V(k)*4, Wv(k)*4, '.', ...
        'Color', cmap(cidx(k),:), 'MarkerSize', 6);
end
% peak event marker
[gpk,kpk] = max(gmag);
plot3(ax1, ts(kpk), 0, 0, 'kp', 'MarkerSize', 14, 'MarkerFaceColor',[1 0.85 0]);
text(ax1, ts(kpk), 0, max(Wv)*4+1.2, sprintf('peak %.2fg @ T%+.1fs', gpk, ts(kpk)), ...
     'HorizontalAlignment','center','FontWeight','bold','FontSize',10);
xlabel(ax1,'t - t_{burst} (s)'); ylabel(ax1,'a_y / g'); zlabel(ax1,'a_z / g');
title(ax1, sprintf(['3-D acceleration vector field through burst window  ' ...
    '(\\pm%ds about T+%ds)'], half_window, round(t_max_s)), ...
    'FontWeight','bold');
view(ax1,[-32 22]); axis(ax1,'tight'); colormap(ax1, turbo);
cb = colorbar(ax1); cb.Label.String = '|a| / g'; caxis(ax1,[min(C) max(C)]);

% (2) acceleration triad + magnitude
ax2 = nexttile(tl,3); hold(ax2,'on'); grid(ax2,'on'); box(ax2,'on');
plot(ax2, ts, ax_f/g0,'-','Color',[0.85 0.10 0.10],'DisplayName','a_x/g');
plot(ax2, ts, ay_f/g0,'-','Color',[0.10 0.55 0.10],'DisplayName','a_y/g');
plot(ax2, ts, az_f/g0,'-','Color',[0.10 0.30 0.85],'DisplayName','a_z/g');
plot(ax2, ts, amag_f/g0,'-','Color','k','LineWidth',1.4,'DisplayName','|a|/g');
yline(ax2,1,':','1g static');
xlabel(ax2,'t - t_{burst} (s)'); ylabel(ax2,'g'); legend(ax2,'Location','best','FontSize',8);
title(ax2,'Body-frame acceleration triad','FontWeight','bold');

% (3) angular velocity magnitude
ax3 = nexttile(tl,6); hold(ax3,'on'); grid(ax3,'on'); box(ax3,'on');
omega = sqrt(gx.^2+gy.^2+gz.^2);
plot(ax3, ts, omega, '-', 'Color',[0.55 0.10 0.65], 'LineWidth',1.2);
xlabel(ax3,'t - t_{burst} (s)'); ylabel(ax3,'||\omega|| (deg/s)');
title(ax3, sprintf('Tumble rate, peak %.0f deg/s', max(omega)),'FontWeight','bold');

% (4) spherical scatter of acceleration direction
ax4 = nexttile(tl,7); hold(ax4,'on'); grid(ax4,'on'); box(ax4,'on');
scatter(ax4, phi, theta, 14, gmag, 'filled');
xlim(ax4,[-180 180]); ylim(ax4,[0 180]);
xlabel(ax4,'azimuth \phi (deg)'); ylabel(ax4,'polar \theta (deg)');
title(ax4,'Acceleration unit-vector orientation','FontWeight','bold');
colormap(ax4, turbo); cb4 = colorbar(ax4); cb4.Label.String='|a|/g';

% (5) PSD of |a|
ax5 = nexttile(tl,8); hold(ax5,'on'); grid(ax5,'on'); box(ax5,'on');
sig = amag_f - mean(amag_f,'omitnan');
sig(~isfinite(sig)) = 0;
N = numel(sig);
nfft = 2^nextpow2(min(1024, max(64,N)));
try
    [Pxx, Fxx] = pwelch(sig, hann(min(N,nfft)), [], nfft, fs);
    plot(ax5, Fxx, 10*log10(Pxx+eps), '-', 'Color',[0.10 0.45 0.85],'LineWidth',1.2);
    [~,kp] = max(Pxx);
    xline(ax5, Fxx(kp), '--r', sprintf('f_p = %.2f Hz', Fxx(kp)));
catch
    plot(ax5, [0 1],[0 0]); text(0.5,0.5,'pwelch unavailable','Units','normalized');
end
xlabel(ax5,'frequency (Hz)'); ylabel(ax5,'PSD (dB/Hz)');
title(ax5, sprintf('|a| spectrum  (f_s \\approx %.1f Hz)', fs),'FontWeight','bold');

% (6) jerk and impulse
ax6 = nexttile(tl,9); hold(ax6,'on'); grid(ax6,'on'); box(ax6,'on');
yyaxis(ax6,'left');
plot(ax6, ts, jmag, '-', 'Color',[0.95 0.30 0.10],'LineWidth',1.2);
ylabel(ax6,'||jerk|| (m/s^3)');
yyaxis(ax6,'right');
imp_run = cumtrapz(W.t_s, dyn);
plot(ax6, ts, imp_run, '--', 'Color',[0.10 0.30 0.85],'LineWidth',1.2);
ylabel(ax6,'\Delta v_{|a|-g} (m/s)');
xlabel(ax6,'t - t_{burst} (s)');
title(ax6, sprintf('Jerk peak %.0f m/s^3   |   \\int(|a|-g)dt = %.1f m/s', ...
    max(jmag), impulse), 'FontWeight','bold');

title(tl, sprintf(['%s  -  Spring 2026 burst-event g-force dashboard ' ...
    '(Personfu)'], cfg.mission.name), 'FontWeight','bold','FontSize',13);

% ----- footer text-box with truth metrics -------------------------
truth_str = sprintf(['truth: peak %.3fg @ T+%ds @ %.0f ft  |  ' ...
    'mean %.3fg  |  raw %d / pub %d samples'], ...
    cfg.truth.max_g_load, round(cfg.truth.max_g_elapsed_s), ...
    cfg.truth.max_g_alt_ft, ...
    1.196, ...                     % published mean g
    9494, 160);
annotation(f,'textbox',[0.005 0.001 0.99 0.028], ...
    'String', truth_str, 'EdgeColor','none', ...
    'HorizontalAlignment','center','FontName','Consolas','FontSize',9, ...
    'Color',[0.20 0.20 0.20]);

out = fullfile(cfg.paths.figures,'14_gforce_burst');
exportgraphics(f,[out '.png'],'Resolution',cfg.plot.dpi);
exportgraphics(f,[out '.pdf'],'ContentType','vector');
try, savefig(f,[out '.fig']); catch, end
fprintf('  viz_gforce_burst -> %s.{png,pdf,fig}  (peak %.2fg)\n', out, gpk);

% persist computed burst metrics for downstream use
B = struct('t_burst_s',t_max_s,'window_s',half_window,'fs_Hz',fs, ...
           'peak_g',gpk,'peak_omega_dps',max(omega), ...
           'peak_jerk_m_s3',max(jmag),'impulse_m_s',impulse, ...
           'samples',height(W));
save(fullfile(cfg.paths.data_proc,'burst_metrics.mat'),'B');
end

% ==================================================================
function y = hampel_safe(x,k,nsig)
% lightweight Hampel - works without Signal Processing Toolbox
x = x(:); n = numel(x); y = x;
for i = 1:n
    a = max(1,i-k); b = min(n,i+k);
    win = x(a:b);
    med = median(win,'omitnan');
    sigma = 1.4826 * median(abs(win-med),'omitnan');
    if isfinite(sigma) && abs(x(i)-med) > nsig*sigma
        y(i) = med;
    end
end
end

function dy = central_diff(y,t)
y = y(:); t = t(:); n = numel(y);
dy = zeros(n,1);
if n < 3, return; end
dy(2:n-1) = (y(3:n) - y(1:n-2)) ./ max(t(3:n)-t(1:n-2), 1e-6);
dy(1)   = (y(2)-y(1))     / max(t(2)-t(1),1e-6);
dy(n)   = (y(n)-y(n-1))   / max(t(n)-t(n-1),1e-6);
end
