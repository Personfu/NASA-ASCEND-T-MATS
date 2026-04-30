function fig = viz_payload_uv_atmo(T, cfg)
%VIZ_PAYLOAD_UV_ATMO  Beer-Lambert UV vs altitude analysis (4x AS7331).
%
%   FIG = VIZ_PAYLOAD_UV_ATMO(T) is the science answer the AS7331 stack
%   was flown to provide: how UVA / UVB / UVC scale with altitude as
%   atmospheric column shrinks. We fit a Beer-Lambert model
%
%       I(h) = I_inf * exp(-tau * exp(-h/H))
%
%   to the 4-sensor mean for each band, plot residuals, and overlay
%   altitude. This is what the carbon-fiber payload was BUILT for.

if nargin < 2 || ~isstruct(cfg), cfg = struct('figdir',''); end
if ~isfield(cfg,'figdir'), cfg.figdir = ''; end

t   = seconds(T.Properties.RowTimes);
alt = T.alt_m;
UVA = mean([T.UV1A T.UV2A T.UV3A T.UV4A], 2, 'omitnan');
UVB = mean([T.UV1B T.UV2B T.UV3B T.UV4B], 2, 'omitnan');
UVC = mean([T.UV1C T.UV2C T.UV3C T.UV4C], 2, 'omitnan');

% Fit Beer-Lambert form via nonlinear LS (lsqcurvefit-free)
H = 8500;
model = @(p,h) p(1) .* exp(-p(2) .* exp(-h ./ H));
opts  = optimset('Display','off');
fitParam = @(I) local_fit(model, alt, I, [max(I,[],'omitnan'), 1.5], opts);

p_a = fitParam(UVA);
p_b = fitParam(UVB);
p_c = fitParam(UVC);

altSweep = linspace(min(alt,[],'omitnan'), max(alt,[],'omitnan'), 200).';

fig = figure('Name','UV vs Altitude','Color','w','Position',[80 60 1280 800]);
tl  = tiledlayout(fig,2,2,'TileSpacing','compact','Padding','compact');
title(tl,'AS7331 x4: UV intensity vs altitude (Beer-Lambert fit)');

ax1 = nexttile(tl,1);
scatter(ax1, alt, UVA, 8, t, 'filled'); hold(ax1,'on');
plot(ax1, altSweep, model(p_a, altSweep), 'r-','LineWidth',1.4);
xlabel(ax1,'Altitude (m)'); ylabel(ax1,'UVA (uW/cm^2)');
title(ax1,sprintf('UVA: I_\\infty = %.1f, \\tau = %.2f', p_a(1), p_a(2)));
grid(ax1,'on'); cb=colorbar(ax1); cb.Label.String='Elapsed (s)';

ax2 = nexttile(tl,2);
scatter(ax2, alt, UVB, 8, t, 'filled'); hold(ax2,'on');
plot(ax2, altSweep, model(p_b, altSweep), 'r-','LineWidth',1.4);
xlabel(ax2,'Altitude (m)'); ylabel(ax2,'UVB (uW/cm^2)');
title(ax2,sprintf('UVB: I_\\infty = %.1f, \\tau = %.2f', p_b(1), p_b(2)));
grid(ax2,'on');

ax3 = nexttile(tl,3);
scatter(ax3, alt, UVC, 8, t, 'filled'); hold(ax3,'on');
plot(ax3, altSweep, model(p_c, altSweep), 'r-','LineWidth',1.4);
xlabel(ax3,'Altitude (m)'); ylabel(ax3,'UVC (uW/cm^2)');
title(ax3,sprintf('UVC: I_\\infty = %.1f, \\tau = %.2f', p_c(1), p_c(2)));
grid(ax3,'on');

ax4 = nexttile(tl,4);
% inter-sensor agreement: std across 4 sensors over time
sA = std([T.UV1A T.UV2A T.UV3A T.UV4A], 0, 2, 'omitnan');
sB = std([T.UV1B T.UV2B T.UV3B T.UV4B], 0, 2, 'omitnan');
sC = std([T.UV1C T.UV2C T.UV3C T.UV4C], 0, 2, 'omitnan');
plot(ax4, t, sA, t, sB, t, sC, 'LineWidth',1.0); grid(ax4,'on');
legend(ax4,{'\sigma UVA','\sigma UVB','\sigma UVC'},'Location','best');
xlabel(ax4,'Elapsed (s)'); ylabel(ax4,'Std across 4 sensors (uW/cm^2)');
title(ax4,'Inter-sensor agreement (lower = better)');

if ~isempty(cfg.figdir)
    if ~isfolder(cfg.figdir), mkdir(cfg.figdir); end
    exportgraphics(fig, fullfile(cfg.figdir,'28_payload_uv_atmo.png'),'Resolution',180);
    exportgraphics(fig, fullfile(cfg.figdir,'28_payload_uv_atmo.pdf'));
end
end

function p = local_fit(model, x, y, p0, opts)
mask = ~isnan(x) & ~isnan(y) & y > 0;
if nnz(mask) < 8, p = p0; return; end
xx = x(mask); yy = y(mask);
res = @(p) model(p, xx) - yy;
try
    p = lsqnonlin(res, p0, [0 0], [Inf 10], opts);
catch
    % gradient-free fallback
    p = fminsearch(@(p) sum(res(p).^2), p0, opts);
end
end
