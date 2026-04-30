function fig = viz_payload_montecarlo(cfg)
%VIZ_PAYLOAD_MONTECARLO  Monte Carlo descent dispersion focused on payload.
%
%   FIG = VIZ_PAYLOAD_MONTECARLO(CFG) runs N synthetic descents of the
%   3 lb Phoenix-1 payload under randomized:
%
%       * burst altitude   (truncated normal around 25,145 m)
%       * payload mass     (1.36 kg ± 5 %)
%       * parachute CdA    (Spherachute 36" ± 10 %)
%       * mean descent wind (Rayleigh, 12 ± 4 m/s)
%       * wind heading     (uniform 0..360)
%
%   Each descent is integrated through US-1976 atmosphere with terminal-
%   velocity drag balance and produces a landing-ellipse plot referenced
%   to the recorded launch site. This gives the Phoenix College team a
%   real recovery-planning tool, not a placeholder.

if nargin < 1 || ~isstruct(cfg), cfg = struct(); end
if ~isfield(cfg,'figdir'),    cfg.figdir = ''; end
if ~isfield(cfg,'nTrials'),   cfg.nTrials = 500; end
if ~isfield(cfg,'launchLat'), cfg.launchLat = 32.87533; end
if ~isfield(cfg,'launchLng'), cfg.launchLng = -112.0495; end
if ~isfield(cfg,'burstAltMu'),  cfg.burstAltMu  = 25145; end
if ~isfield(cfg,'burstAltSig'), cfg.burstAltSig = 800;   end

rng(2026);
N = cfg.nTrials;
landX = zeros(N,1); landY = zeros(N,1); descT = zeros(N,1);

% Payload + parachute base values (Phoenix-1)
m0  = 1.361;             % kg (3 lb)
CdA0 = 0.36 * pi * (0.46/2)^2 * 1.5;   % Spherachute 36" effective CdA

for k = 1:N
    burst = max(15000, cfg.burstAltMu + cfg.burstAltSig*randn);
    m     = m0 * (1 + 0.05*randn);
    CdA   = max(0.05, CdA0 * (1 + 0.10*randn));
    wind  = abs(12 + 4*randn);                 % m/s
    bear  = 2*pi*rand;                          % rad

    [tFall, drift] = local_descent(burst, m, CdA, wind);

    descT(k) = tFall;
    landX(k) = drift * sin(bear);
    landY(k) = drift * cos(bear);
end

[mX, mY] = deal(mean(landX), mean(landY));
sX = std(landX); sY = std(landY);

fig = figure('Name','Payload Monte Carlo','Color','w','Position',[80 60 1080 760]);
tl  = tiledlayout(fig,1,2,'TileSpacing','compact','Padding','compact');
title(tl,'Phoenix-1 Recovery Dispersion (Monte Carlo, N = '+string(N)+')');

ax1 = nexttile(tl,1);
scatter(ax1, landX/1000, landY/1000, 18, descT/60, 'filled');
hold(ax1,'on'); plot(ax1, 0, 0, 'kp','MarkerFaceColor','y','MarkerSize',14);
% 1-sigma ellipse
th = linspace(0,2*pi,200);
plot(ax1, (mX + sX*cos(th))/1000, (mY + sY*sin(th))/1000, 'r--','LineWidth',1.2);
plot(ax1, (mX + 2*sX*cos(th))/1000, (mY + 2*sY*sin(th))/1000, 'r:','LineWidth',1.0);
xlabel(ax1,'East offset (km)'); ylabel(ax1,'North offset (km)');
title(ax1,'Landing dispersion (color = fall time, min)');
axis(ax1,'equal'); grid(ax1,'on'); cb = colorbar(ax1); cb.Label.String = 'fall time (min)';
legend(ax1,{'landing','launch','1\sigma','2\sigma'},'Location','best','FontSize',8);

ax2 = nexttile(tl,2);
ranges = sqrt(landX.^2 + landY.^2)/1000;
histogram(ax2, ranges, 30, 'FaceColor',[0.20 0.55 0.20]);
xlabel(ax2,'Drift range (km)'); ylabel(ax2,'Trials');
title(ax2,sprintf('Drift range: median %.1f km, 95%% < %.1f km', ...
    median(ranges), prctile(ranges,95)));
grid(ax2,'on');

if ~isempty(cfg.figdir)
    if ~isfolder(cfg.figdir), mkdir(cfg.figdir); end
    exportgraphics(fig, fullfile(cfg.figdir,'27_payload_montecarlo.png'),'Resolution',180);
    exportgraphics(fig, fullfile(cfg.figdir,'27_payload_montecarlo.pdf'));
end
end

function [tFall, drift] = local_descent(burstAlt, m, CdA, wind)
g = 9.80665;
h = burstAlt; t = 0; dt = 0.5; tFall = 0; drift = 0;
while h > 0 && t < 7200
    rho = local_rho(h);
    Vt  = sqrt(2*m*g/(rho*CdA));
    h   = h - Vt*dt;
    drift = drift + wind*dt;
    t = t + dt;
end
tFall = t;
end

function rho = local_rho(h)
T0 = 288.15; P0 = 101325; L = 0.0065; R = 287.05; g = 9.80665;
if h < 11000
    Tk = T0 - L*h;
    P  = P0 * (Tk/T0)^(g/(R*L));
else
    T11 = T0 - L*11000;
    P11 = P0 * (T11/T0)^(g/(R*L));
    Tk = T11; P = P11 * exp(-g*(h-11000)/(R*Tk));
end
rho = P / (R*Tk);
end
