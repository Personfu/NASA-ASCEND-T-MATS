function viz_payload_3d_render(PS, cfg)
%VIZ_PAYLOAD_3D_RENDER  Programmatic 3-D payload assembly diagram.
%
%   Builds a simplified but dimensionally-traceable solid model of
%   the Spring 2026 flight string: foamcore/HDPE box with 6 internal
%   subsystem volumes positioned at their measured CGs, plus a
%   ring antenna stub, parachute attachment and train line.
%
%   Output: figures/12_payload_3d.png|pdf|fig

% box envelope (m)
L = 0.30; W = 0.30; H = 0.20;     % external 30x30x20 cm
wall = 0.012;

f = figure('Color','w','Position',[80 80 1400 900],'Name','Payload 3-D render');
tl = tiledlayout(f,1,2,'TileSpacing','compact','Padding','compact');

ax1 = nexttile; hold(ax1,'on');
draw_box(ax1,[-L/2 -W/2 0],[L W H],[0.95 0.95 0.95],0.08,'Foamcore enclosure');

% subsystem placement (relative to box volume) ---------------------
sub = struct();
sub.tracker  = struct('p',[ -0.10 -0.10  0.04 ],'sz',[0.07 0.05 0.025],'c',[0.10 0.45 0.85],'name','APRS tracker');
sub.multi    = struct('p',[  0.05 -0.10  0.05 ],'sz',[0.09 0.06 0.030],'c',[0.10 0.65 0.55],'name','Multisensor');
sub.arduino  = struct('p',[ -0.10  0.05  0.05 ],'sz',[0.10 0.07 0.035],'c',[0.55 0.10 0.65],'name','Arduino sci stack');
sub.geiger   = struct('p',[  0.05  0.05  0.04 ],'sz',[0.11 0.06 0.030],'c',[0.85 0.10 0.45],'name','GMC-320+');
sub.battery  = struct('p',[ -0.04 -0.02  0.12 ],'sz',[0.07 0.06 0.040],'c',[0.95 0.55 0.10],'name','Li battery 8x AA');
sub.parach   = struct('p',[ -0.02  0.00  0.18 ],'sz',[0.04 0.04 0.020],'c',[0.20 0.55 0.20],'name','Chute attach');

flds = fieldnames(sub);
for k = 1:numel(flds)
    s = sub.(flds{k});
    draw_box(ax1, s.p, s.sz, s.c, 0.85, '');
    text(ax1, s.p(1)+s.sz(1)/2, s.p(2)+s.sz(2)/2, s.p(3)+s.sz(3)+0.012, s.name, ...
        'FontSize',8,'HorizontalAlignment','center','FontWeight','bold');
end

% antenna stub
plot3(ax1,[0 0],[0 0],[H H+0.18],'k-','LineWidth',2.0);
text(ax1,0,0,H+0.20,'1/4\lambda 144.39 MHz','HorizontalAlignment','center','FontSize',8);

% train line / parachute up
plot3(ax1,[0 0],[0 0],[H+0.0 H+0.55],'-','Color',[0.5 0.5 0.5],'LineWidth',1.2);
plot3(ax1,[0 -0.10 0 0.10 0],[0 0 0 0 0],[H+0.55 H+0.65 H+0.80 H+0.65 H+0.55], ...
      '-','Color',[0.20 0.55 0.20],'LineWidth',1.5);
text(ax1,0,0,H+0.85,'36" Spherachute','HorizontalAlignment','center','FontSize',9,'FontWeight','bold');

axis(ax1,'equal'); grid(ax1,'on'); box(ax1,'on');
xlabel(ax1,'X (m)'); ylabel(ax1,'Y (m)'); zlabel(ax1,'Z (m)');
view(ax1,[-37 22]); camlight(ax1,'headlight'); lighting(ax1,'gouraud');
title(ax1,'Internal layout (cutaway, lid removed)','FontWeight','bold');

% ----- second tile : exploded mass / CG / MOI summary -------------
ax2 = nexttile; hold(ax2,'on');
if nargin>=1 && isfield(PS,'totals')
    names = {'tracker','multi','arduino','geiger','power','parachute'};
    masses = arrayfun(@(n) PS.(n{1}).mass_g, names);
    bar(ax2, masses, 'FaceColor', cfg.plot.colors.uv, 'EdgeColor','k');
    set(ax2,'XTick',1:numel(names),'XTickLabel',names);
    ylabel(ax2,'mass (g)'); grid(ax2,'on'); box(ax2,'on');
    title(ax2,sprintf('Subsystem mass budget  -  total %.2f kg', PS.totals.mass_kg), ...
        'FontWeight','bold');
    for k=1:numel(masses)
        text(ax2,k,masses(k)+8,sprintf('%.0f g',masses(k)), ...
            'HorizontalAlignment','center','FontSize',9);
    end
end

title(tl, sprintf('%s  -  Payload assembly (Personfu)', cfg.mission.name), ...
      'FontWeight','bold','FontSize',13);

out = fullfile(cfg.paths.figures,'12_payload_3d');
exportgraphics(f,[out '.png'],'Resolution',cfg.plot.dpi);
exportgraphics(f,[out '.pdf'],'ContentType','vector');
try, savefig(f,[out '.fig']); catch, end
fprintf('  viz_payload_3d_render -> %s.{png,pdf,fig}\n', out);
end

% ------------------------------------------------------------------
function draw_box(ax,p,sz,col,alpha,~)
x = p(1); y = p(2); z = p(3);
dx= sz(1); dy = sz(2); dz = sz(3);
V = [x y z; x+dx y z; x+dx y+dy z; x y+dy z;
     x y z+dz; x+dx y z+dz; x+dx y+dy z+dz; x y+dy z+dz];
F = [1 2 3 4; 5 6 7 8; 1 2 6 5; 2 3 7 6; 3 4 8 7; 4 1 5 8];
patch(ax,'Vertices',V,'Faces',F,'FaceColor',col, ...
      'FaceAlpha',alpha,'EdgeColor',[0.2 0.2 0.2],'LineWidth',0.6);
end
