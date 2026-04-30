function viz_payload_power(PE, cfg)
%VIZ_PAYLOAD_POWER  Electrical bus + battery analysis for the
%   Phoenix-1 payload (Personfu).
%
%   Builds a transient bus profile by laying out duty cycles for each
%   subsystem across a 96-min flight, computes:
%     - instantaneous power, cumulative energy, depth-of-discharge
%     - state-of-charge curve for 8x AA L91 lithium primary
%     - voltage sag estimate via internal resistance model
%     - thermal dissipation by subsystem
%
%   Output: figures/19_payload_power.{png,pdf}

% subsystem duty cycles (W, duty, period_s)
%   power averaged over period gives bus contribution
S = {
    'Arduino + sensors',  0.65, 1.00, 1;
    'BMP+IMU+SD I/O',     0.20, 1.00, 1;
    'Geiger detector',    0.35, 1.00, 1;
    'PMS5003 fan',        0.50, 0.30, 60;     % cycled 30% per minute
    'SCD41 measurement',  0.25, 0.20, 30;
    'APRS TX burst',      4.50, 0.02, 60;     % 1.2 s tx every 60 s
    'GPS lock',           0.30, 1.00, 1;
    'LED status',         0.05, 1.00, 1;
};
labels = S(:,1); P = cell2mat(S(:,2)); duty = cell2mat(S(:,3));
P_avg  = P .* duty;
Ptot_W = sum(P_avg);

t = (0:1:5760).';   % 96 min in seconds
P_t = zeros(size(t));
for k = 1:size(S,1)
    period = S{k,4};
    onlen  = round(duty(k)*period);
    pat    = zeros(period,1); pat(1:onlen) = P(k);
    rep    = repmat(pat, ceil(numel(t)/period),1);
    P_t = P_t + rep(1:numel(t));
end

E_used = cumtrapz(t, P_t)/3600;          % Wh
Ebatt  = PE.electrical.bus_capacity_Wh;
SoC    = max(0, 1 - E_used/Ebatt);

% voltage sag (internal R per AA ~ 0.15 Ohm, 8 in series ~ 1.2 Ohm)
Rint = 1.2;  Voc = 12.0;
I_t  = P_t / Voc;
Vbus = Voc - I_t * Rint;
Vbus = max(Vbus, 9.0);

f = figure('Color','w','Position',[40 40 1500 950], ...
    'Name','Payload power bus (Personfu)');
tl = tiledlayout(f,2,2,'TileSpacing','compact','Padding','compact');

ax = nexttile; hold(ax,'on'); grid(ax,'on'); box(ax,'on');
plot(ax, t/60, P_t,'-','Color',[0.95 0.55 0.10],'LineWidth',0.6);
xlabel(ax,'time (min)'); ylabel(ax,'P_{bus} (W)');
yline(ax, Ptot_W,'--k',sprintf('avg %.2f W',Ptot_W));
title(ax,'Instantaneous bus power','FontWeight','bold');

ax = nexttile; hold(ax,'on'); grid(ax,'on'); box(ax,'on');
plot(ax, t/60, E_used,'-','Color',[0.10 0.30 0.85],'LineWidth',1.5);
xlabel(ax,'time (min)'); ylabel(ax,'energy used (Wh)');
yline(ax, Ebatt,'--k',sprintf('cap %.1f Wh',Ebatt));
title(ax,'Cumulative energy','FontWeight','bold');

ax = nexttile; hold(ax,'on'); grid(ax,'on'); box(ax,'on');
plot(ax, t/60, SoC*100,'-','Color',[0.10 0.55 0.20],'LineWidth',1.6);
xlabel(ax,'time (min)'); ylabel(ax,'SoC (%)');
ylim(ax,[0 105]);
title(ax,sprintf('Battery SoC  (DoD = %.1f%%)', (1-SoC(end))*100),'FontWeight','bold');

ax = nexttile; hold(ax,'on'); grid(ax,'on'); box(ax,'on');
b = bar(ax, P_avg,'FaceColor',[0.55 0.10 0.65],'EdgeColor','k');
set(ax,'XTick',1:numel(labels),'XTickLabel',labels);
ylabel(ax,'avg P (W)');
xtickangle(ax,30);
for k=1:numel(P_avg)
    text(ax,k,P_avg(k)+0.02,sprintf('%.2f',P_avg(k)), ...
        'HorizontalAlignment','center','FontSize',8);
end
title(ax,'Avg power per subsystem','FontWeight','bold');

title(tl,sprintf('%s power bus (Personfu) - 8x AA L91 / 12V / %.0f Wh', ...
    PE.name, Ebatt),'FontWeight','bold','FontSize',13);

out = fullfile(cfg.paths.figures,'19_payload_power');
exportgraphics(f,[out '.png'],'Resolution',cfg.plot.dpi);
exportgraphics(f,[out '.pdf'],'ContentType','vector');
fprintf('  viz_payload_power      -> %s.{png,pdf}\n', out);
end
