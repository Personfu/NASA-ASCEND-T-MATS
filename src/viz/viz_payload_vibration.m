function fig = viz_payload_vibration(T, cfg)
%VIZ_PAYLOAD_VIBRATION  FFT / PSD vibration analysis of the payload IMU.
%
%   FIG = VIZ_PAYLOAD_VIBRATION(T) computes per-axis power spectral
%   densities of the BNO055 accel/gyro using Welch's method, plots
%   stack-up spectrograms across the flight, and identifies dominant
%   tones (typical: balloon rotation 0.05-0.3 Hz, parachute oscillation
%   0.4-1.2 Hz, structural payload modes 5-30 Hz).
%
%   This is the "advanced engineering" answer to: "what frequencies are
%   the carbon-fiber tube and 3-D printed internals exposed to?"

if nargin < 2 || ~isstruct(cfg), cfg = struct('figdir',''); end
if ~isfield(cfg,'figdir'), cfg.figdir = ''; end

t  = seconds(T.Properties.RowTimes);
dt = median(diff(t)); if isnan(dt) || dt<=0, dt = 0.5; end
fs = 1/dt;

ax = T.accelX - mean(T.accelX,'omitnan');
ay = T.accelY - mean(T.accelY,'omitnan');
az = T.accelZ - mean(T.accelZ,'omitnan');

% Welch PSD per axis
nfft = 2^nextpow2(min(numel(t), 1024));
[Px, f] = local_pwelch(ax, fs, nfft);
[Py, ~] = local_pwelch(ay, fs, nfft);
[Pz, ~] = local_pwelch(az, fs, nfft);

% Spectrogram of |a|
amag = sqrt(ax.^2 + ay.^2 + az.^2);

fig = figure('Name','Payload Vibration','Color','w','Position',[80 60 1280 900]);
tl  = tiledlayout(fig,2,2,'TileSpacing','compact','Padding','compact');
title(tl,'Phoenix-1 Vibration Spectrum (BNO055 accel)');

ax1 = nexttile(tl,1);
loglog(ax1, f, Px, f, Py, f, Pz, 'LineWidth',1.0); grid(ax1,'on');
legend(ax1,{'a_x','a_y','a_z'},'Location','southwest');
xlabel(ax1,'Frequency (Hz)'); ylabel(ax1,'PSD (m^2/s^4/Hz)');
title(ax1,'Welch PSD per Axis');

ax2 = nexttile(tl,2);
plot(ax2, t, amag, 'LineWidth',0.8); grid(ax2,'on');
xlabel(ax2,'Elapsed (s)'); ylabel(ax2,'|a| (m/s^2)');
title(ax2,'Acceleration Magnitude');

ax3 = nexttile(tl,3);
% Crude STFT: sliding 64-sample window
W = min(64, floor(numel(t)/8));
if W < 16, W = 16; end
hop = max(1, floor(W/2));
nWin = max(1, floor((numel(t)-W)/hop));
S = zeros(W/2+1, nWin);
tw = zeros(nWin,1);
for k = 1:nWin
    i1 = (k-1)*hop + 1;
    i2 = i1 + W - 1;
    if i2 > numel(t), break; end
    seg = (amag(i1:i2) - mean(amag(i1:i2))) .* hann(W);
    F   = fft(seg);
    S(:,k) = abs(F(1:W/2+1));
    tw(k)  = t(round((i1+i2)/2));
end
freqs = (0:W/2) * fs / W;
imagesc(ax3, tw, freqs, 20*log10(S+eps)); axis(ax3,'xy');
xlabel(ax3,'Elapsed (s)'); ylabel(ax3,'Frequency (Hz)');
title(ax3,'STFT Spectrogram of |a| (dB)');
colorbar(ax3);

ax4 = nexttile(tl,4);
% Histogram of |a| during DESCENT phase
descMask = (T.phase == 3);
if any(descMask)
    histogram(ax4, amag(descMask), 60, 'FaceColor',[0.85 0.30 0.20]);
else
    histogram(ax4, amag, 60, 'FaceColor',[0.30 0.55 0.85]);
end
xlabel(ax4,'|a| (m/s^2)'); ylabel(ax4,'Count');
title(ax4,'Acceleration Distribution (DESCENT phase)');
grid(ax4,'on');

if ~isempty(cfg.figdir)
    if ~isfolder(cfg.figdir), mkdir(cfg.figdir); end
    exportgraphics(fig, fullfile(cfg.figdir,'24_payload_vibration.png'),'Resolution',180);
    exportgraphics(fig, fullfile(cfg.figdir,'24_payload_vibration.pdf'));
end
end

function [Pxx, f] = local_pwelch(x, fs, nfft)
% Minimal Welch PSD without DSP toolbox
x = x(:); x(isnan(x)) = 0;
N = numel(x);
seg = min(nfft, N);
hop = floor(seg/2);
w = 0.5 - 0.5*cos(2*pi*(0:seg-1).'/(seg-1));
nSeg = max(1, floor((N - seg)/hop) + 1);
Pxx = zeros(seg/2+1, 1);
for k = 1:nSeg
    i1 = (k-1)*hop + 1;
    i2 = i1 + seg - 1;
    if i2 > N, break; end
    s  = x(i1:i2) .* w;
    F  = fft(s, seg);
    P  = (abs(F).^2) / (fs * sum(w.^2));
    P  = P(1:seg/2+1); P(2:end-1) = 2*P(2:end-1);
    Pxx = Pxx + P;
end
Pxx = Pxx / nSeg;
f   = (0:seg/2).' * fs / seg;
end
