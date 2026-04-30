function fig = viz_payload_allan(T, cfg)
%VIZ_PAYLOAD_ALLAN  Allan deviation of BNO055 gyro (sensor characterisation).
%
%   FIG = VIZ_PAYLOAD_ALLAN(T) computes the overlapping Allan deviation
%   of each gyro axis over the cleanest static portion of the flight
%   (ground phase, before launch). This is the standard inertial-sensor
%   characterisation curve used to extract:
%
%       * Angle Random Walk  (slope -1/2 segment)
%       * Bias Instability   (flat minimum)
%       * Rate Random Walk   (slope +1/2 segment)
%
%   Computed without the Aerospace Toolbox.

if nargin < 2 || ~isstruct(cfg), cfg = struct('figdir',''); end
if ~isfield(cfg,'figdir'), cfg.figdir = ''; end

t   = seconds(T.Properties.RowTimes);
dt  = median(diff(t)); if isnan(dt) || dt<=0, dt = 0.5; end
fs  = 1/dt;

mask = (T.phase == 0);
if nnz(mask) < 64
    mask = true(size(t));   % fall back to full record
end
gx = T.gyroX(mask); gy = T.gyroY(mask); gz = T.gyroZ(mask);

[tau, ax_dev] = local_allan(gx, fs);
[~,   ay_dev] = local_allan(gy, fs);
[~,   az_dev] = local_allan(gz, fs);

fig = figure('Name','Payload Allan Deviation','Color','w','Position',[80 60 980 700]);
loglog(tau, ax_dev, tau, ay_dev, tau, az_dev, 'LineWidth',1.4); grid on;
legend({'gyro X','gyro Y','gyro Z'}, 'Location','southwest');
xlabel('\tau (s)'); ylabel('\sigma_y(\tau) (deg/s)');
title('BNO055 Gyro Allan Deviation (ground-phase samples)');

if ~isempty(cfg.figdir)
    if ~isfolder(cfg.figdir), mkdir(cfg.figdir); end
    exportgraphics(fig, fullfile(cfg.figdir,'26_payload_allan.png'),'Resolution',180);
    exportgraphics(fig, fullfile(cfg.figdir,'26_payload_allan.pdf'));
end
end

function [tau, sigma] = local_allan(x, fs)
% Overlapping Allan deviation
x = x(:); x(isnan(x)) = 0;
N = numel(x);
maxM = floor(N/3);
mList = unique(round(logspace(0, log10(max(2,maxM)), 30)));
mList = mList(mList >= 1 & mList <= maxM);
tau   = mList(:) / fs;
sigma = zeros(size(tau));
% Cumulative sum trick for averaging
cs = [0; cumsum(x)];
for i = 1:numel(mList)
    m = mList(i);
    yk = (cs(m+1:end) - cs(1:end-m)) / m;     % m-sample averages
    if numel(yk) < 3, sigma(i) = NaN; continue; end
    d  = diff(yk);                            % overlapping diff
    sigma(i) = sqrt(0.5 * mean(d.^2));
end
end
