function viz_payload_link_budget(PE, D, cfg)
%VIZ_PAYLOAD_LINK_BUDGET  APRS link budget vs slant range &
%   altitude, with antenna pattern, fade margin, and ground-station
%   visibility envelope.  Designed by Personfu.
%
%   Output: figures/20_payload_link_budget.{png,pdf}

C = PE.comms;
fMHz = C.aprs.freq_MHz;  Pt_W = C.aprs.tx_W; Gt = C.aprs.gain_dBi;
Gr = C.gnd.gain_dBi;     NF = C.gnd.NF_dB;
B  = 16e3;               % AFSK bandwidth
kT = 1.38064852e-23 * 290;
Nfloor_dBm = 10*log10(kT*B*1000) + NF;

% sweep
d_km = logspace(log10(0.1), log10(800), 250).';
fspl = 32.45 + 20*log10(fMHz) + 20*log10(d_km);
% atmospheric loss small at VHF (~0.01 dB/km)
atm  = 0.01 * d_km;
Pt_dBm = 10*log10(Pt_W*1000);
Prx    = Pt_dBm + Gt - fspl - atm + Gr;
SNR    = Prx - Nfloor_dBm;
margin = SNR - 10;          % 10 dB demod threshold

% antenna pattern (1/4 lambda whip over GP) approx
phi = linspace(0,pi,180);
G_phi = 1.5 * sin(phi).^2;          % linear gain pattern relative to peak
G_phi_dBi = 10*log10(max(G_phi,1e-3)) + 0.0;

% horizon distance vs altitude (geometric)
h = linspace(0, 26000, 200);
Re = 6371000;
horizon_km = sqrt(2*Re*h + h.^2)/1000;

f = figure('Color','w','Position',[40 40 1500 920], ...
    'Name','APRS link budget (Personfu)');
tl = tiledlayout(f,2,2,'TileSpacing','compact','Padding','compact');

ax = nexttile; hold(ax,'on'); grid(ax,'on'); box(ax,'on');
plot(ax, d_km, Prx,'-','Color',[0.10 0.45 0.85],'LineWidth',1.5);
yline(ax, Nfloor_dBm,'--r','noise floor');
yline(ax, Nfloor_dBm+10,':k','demod threshold');
xlabel(ax,'slant range (km)'); ylabel(ax,'P_{rx} (dBm)');
set(ax,'XScale','log'); title(ax,'Received power vs range','FontWeight','bold');

ax = nexttile; hold(ax,'on'); grid(ax,'on'); box(ax,'on');
plot(ax, d_km, margin,'-','Color',[0.10 0.55 0.20],'LineWidth',1.5);
yline(ax,0,'--r','margin = 0');
xlabel(ax,'slant range (km)'); ylabel(ax,'link margin (dB)');
set(ax,'XScale','log'); title(ax,'Link margin (10 dB demod target)','FontWeight','bold');

ax = nexttile; hold(ax,'on');
polarplot_local(ax, [phi, -phi(end-1:-1:1)], [G_phi_dBi, G_phi_dBi(end-1:-1:1)] - min(G_phi_dBi));
title(ax,sprintf('Whip pattern (peak %.1f dBi)', max(G_phi_dBi)),'FontWeight','bold');

ax = nexttile; hold(ax,'on'); grid(ax,'on'); box(ax,'on');
plot(ax, h/1000, horizon_km,'-','Color',[0.85 0.10 0.45],'LineWidth',1.5);
if isfield(D,'trajectory') && height(D.trajectory)>10
    apex = max(D.trajectory.alt_m);
    xline(ax, apex/1000,'--k',sprintf('apex %.1f km',apex/1000));
end
xlabel(ax,'altitude (km)'); ylabel(ax,'horizon (km)');
title(ax,'Geometric LOS horizon','FontWeight','bold');

title(tl, sprintf('%s APRS link budget @ %.3f MHz / %.1f W (Personfu)', ...
    PE.name, fMHz, Pt_W),'FontWeight','bold','FontSize',13);

out = fullfile(cfg.paths.figures,'20_payload_link_budget');
exportgraphics(f,[out '.png'],'Resolution',cfg.plot.dpi);
exportgraphics(f,[out '.pdf'],'ContentType','vector');
fprintf('  viz_payload_link_budget -> %s.{png,pdf}\n', out);
end

function polarplot_local(ax, theta, r)
x = r.*cos(theta); y = r.*sin(theta);
fill(ax, x, y, [0.10 0.45 0.85],'FaceAlpha',0.25,'EdgeColor',[0.10 0.45 0.85],'LineWidth',1.6);
axis(ax,'equal'); axis(ax,'off');
end
