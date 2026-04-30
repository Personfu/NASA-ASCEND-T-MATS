function viz_payload(PS, cfg)
%VIZ_PAYLOAD  Mass-properties dashboard for the Spring 2026 flight string.
%
%   Generates a 2x2 figure with:
%       (1) Stacked bar of subsystem mass in grams
%       (2) Pie chart of power consumption per subsystem (continuous + heater duty)
%       (3) 3D scatter of subsystem CGs (mm) with symbols sized by mass
%       (4) Stem plot of moment-of-inertia diagonal entries about the aggregate CG

mods = {'tracker','multi','arduino','geiger','power'};
labels = {'APRS Tracker','Multisensor (PMx/CO2)','Arduino Stack','Geiger','Battery'};
m_g  = arrayfun(@(k) PS.(mods{k}).mass_g,        1:numel(mods));
P_W  = arrayfun(@(k) get_power(PS.(mods{k})),    1:numel(mods));
cg_mm = cell2mat(arrayfun(@(k) PS.(mods{k}).cg_mm, 1:numel(mods),'UniformOutput',false)');

f = figure('Color','w','Units','pixels','Position',[60 60 1280 880],'Visible','off');
tiledlayout(f,2,2,'Padding','compact','TileSpacing','compact');

% --- 1: mass
nexttile; bar(categorical(labels), m_g, 'FaceColor',[0.20 0.45 0.75]);
ylabel('mass (g)'); grid on; title(sprintf('Subsystem mass (total dry %.0f g)', PS.totals.dry_mass_g));
text(1:numel(m_g), m_g, compose('%.0f', m_g), 'HorizontalAlignment','center', ...
    'VerticalAlignment','bottom','FontWeight','bold');

% --- 2: power
nexttile; pie(P_W, labels);
title(sprintf('Power draw (sum = %.2f W bus)', sum(P_W)));

% --- 3: CG geometry
nexttile;
sz = 60 * (m_g/min(m_g));
scatter3(cg_mm(:,1), cg_mm(:,2), cg_mm(:,3), sz, 1:numel(mods), 'filled'); hold on;
% aggregate CG
cgT = PS.totals.cg_m*1000;
plot3(cgT(1),cgT(2),cgT(3),'kp','MarkerSize',18,'MarkerFaceColor','y');
text(cg_mm(:,1)+5, cg_mm(:,2), cg_mm(:,3), labels);
xlabel('x_{fwd} (mm)'); ylabel('y_{stbd} (mm)'); zlabel('z_{down} (mm)');
title('Subsystem CG (yellow star = aggregate CG)'); grid on; axis equal; view(135,25);

% --- 4: MOI diagonal
nexttile;
J = PS.totals.moi_kgm2;
diagJ = diag(J);
stem(1:3, diagJ*1e3, 'filled','LineWidth',2);
set(gca,'XTick',1:3,'XTickLabel',{'I_{xx}','I_{yy}','I_{zz}'});
ylabel('moment of inertia (g\cdot m^2)');
grid on; title(sprintf('Aggregate MOI about CG  (areal density %.2f psi, FAA %s)', ...
    PS.faa.areal_density_psi, ternary(PS.faa.compliant,'OK','VIOLATION')));

sgtitle(f, 'ASCEND Spring 2026 - Payload Mass / Power / Inertia', 'FontWeight','bold');

base = fullfile(cfg.paths.figures,'08_payload');
for k=1:numel(cfg.plot.export_formats)
    exportgraphics(f, [base,'.',cfg.plot.export_formats{k}],'Resolution',cfg.plot.dpi);
end
fprintf('  saved -> %s.{%s}\n', base, strjoin(cfg.plot.export_formats,','));
close(f);
end

function P = get_power(s)
if isfield(s,'power_W'),       P = s.power_W;
elseif isfield(s,'power_idle_W'), P = s.power_idle_W;
elseif isfield(s,'pack') && isfield(s.pack,'energy_Wh'), P = 0.05;   % battery loss
else, P = 0;
end
end

function out = ternary(c,a,b), if c, out=a; else, out=b; end, end
