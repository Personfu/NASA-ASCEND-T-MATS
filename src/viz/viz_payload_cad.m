function viz_payload_cad(PE, cfg)
%VIZ_PAYLOAD_CAD  Programmatic CAD-grade rendering of the actual
%   Spring 2026 flight article: carbon-fiber wrapped 3-D printed
%   cylindrical body with red painted mid-section, two black CF
%   retention bands, top truss cap, bottom optical/vent dome, and
%   4-point bridle harness.  Designed by Personfu.
%
%   Not a placeholder block-out: this routine builds true cylindrical
%   surfaces, the truss cap as a lattice of struts, the bottom dome
%   as a hemisphere of revolution, the bridle as catenary lines, and
%   the antenna whip as a vertical extrusion.
%
%   Output:  figures/15_payload_cad.{png,pdf,fig}

if nargin < 2; error('viz_payload_cad: cfg required'); end
G = PE.geometry;

f = figure('Color','w','Position',[40 40 1480 980], ...
           'Name','Payload CAD render (Personfu)');
tl = tiledlayout(f,1,2,'TileSpacing','compact','Padding','compact');

% ===== left: full assembly ========================================
axA = nexttile(tl); hold(axA,'on');
draw_assembly(axA, G, PE);
axis(axA,'equal'); grid(axA,'on'); box(axA,'on');
view(axA,[-32 18]); camlight(axA,'headlight'); lighting(axA,'gouraud');
xlabel(axA,'X (m)'); ylabel(axA,'Y (m)'); zlabel(axA,'Z (m)');
title(axA,sprintf('%s  -  flight assembly', PE.name),'FontWeight','bold');

% ===== right: cutaway with internal stack =========================
axB = nexttile(tl); hold(axB,'on');
draw_assembly(axB, G, PE, true);
draw_internal_stack(axB, PE);
axis(axB,'equal'); grid(axB,'on'); box(axB,'on');
view(axB,[35 16]); camlight(axB,'headlight'); lighting(axB,'gouraud');
xlabel(axB,'X (m)'); ylabel(axB,'Y (m)'); zlabel(axB,'Z (m)');
title(axB,'cutaway: internal subsystem stack','FontWeight','bold');

title(tl, sprintf(['Phoenix-1 carbon-fiber payload  -  m=%.3f kg, ' ...
    'CG=[%.2f %.2f %.2f] m  (Personfu)'], PE.totals.mass_kg, PE.totals.CG_m), ...
    'FontWeight','bold','FontSize',13);

out = fullfile(cfg.paths.figures,'15_payload_cad');
exportgraphics(f,[out '.png'],'Resolution',cfg.plot.dpi);
exportgraphics(f,[out '.pdf'],'ContentType','vector');
try, savefig(f,[out '.fig']); catch, end
fprintf('  viz_payload_cad        -> %s.{png,pdf,fig}\n', out);
end

% ==================================================================
function draw_assembly(ax, G, PE, cutaway)
if nargin<4, cutaway=false; end
R = G.body_OD_mm/2000;
H = G.body_H_mm/1000;
Hcap = G.cap_H_mm/1000;
Hdom = G.dome_H_mm/1000;
z0 = Hdom;                 % body starts above dome

theta = linspace(0,2*pi,80);
if cutaway
    theta = linspace(-pi/3, 4*pi/3, 60);   % open ~120 deg cutaway
end

% ----- bottom dome (hemisphere of revolution) ---------------------
phi = linspace(-pi/2,0,24);
[Th,Ph] = meshgrid(theta,phi);
Xd = R*cos(Th).*cos(Ph);
Yd = R*sin(Th).*cos(Ph);
Zd = Hdom + R*sin(Ph);
surf(ax,Xd,Yd,Zd,'FaceColor',hex2rgb(PE.color.vent), ...
    'EdgeColor','none','FaceAlpha',0.95);

% ----- main cylindrical body (red CF-wrapped) ---------------------
zb = linspace(z0, z0+H, 30);
[Th,Zb] = meshgrid(theta, zb);
Xb = R*cos(Th); Yb = R*sin(Th);
% color band map: black at H/3 and 2H/3, red elsewhere
band1 = abs(Zb-(z0+H/3))   < (G.band_w_mm/2000);
band2 = abs(Zb-(z0+2*H/3)) < (G.band_w_mm/2000);
top   = abs(Zb-(z0+H))     < (G.band_w_mm/2000);
bot   = abs(Zb-z0)         < (G.band_w_mm/2000);
isBlack = band1 | band2 | top | bot;
C = repmat(reshape(hex2rgb(PE.color.body),1,1,3), size(Xb,1),size(Xb,2),1);
black = reshape([0.05 0.05 0.06],1,1,3);
C(isBlack) = repmat(black, sum(isBlack(:)), 1);
surf(ax, Xb, Yb, Zb, C, 'EdgeColor','none','FaceAlpha',0.97);

% ----- top truss cap (lattice) ------------------------------------
zc0 = z0 + H;
zc1 = zc0 + Hcap;
% outer skin
zct = linspace(zc0, zc1, 8);
[Th,Zc] = meshgrid(theta, zct);
Xc = R*cos(Th); Yc = R*sin(Th);
surf(ax,Xc,Yc,Zc,'FaceColor',[0.06 0.06 0.07],'EdgeColor','none','FaceAlpha',0.9);
% truss strut grid
for k = 0:11
    a1 = k*pi/6; a2 = (k+1)*pi/6;
    plot3(ax, R*[cos(a1) cos(a2)], R*[sin(a1) sin(a2)], [zc0 zc1], ...
        '-','Color',[0.85 0.85 0.85],'LineWidth',0.7);
    plot3(ax, R*[cos(a1) cos(a2)], R*[sin(a1) sin(a2)], [zc1 zc0], ...
        '-','Color',[0.85 0.85 0.85],'LineWidth',0.7);
end
% cap ring
plot3(ax, R*cos(theta), R*sin(theta), zc1*ones(size(theta)), ...
    '-','Color',[0.5 0.5 0.5],'LineWidth',1.2);

% ----- 4 bridle hard-points + lines -------------------------------
zb_top = zc1;
ang = (0:3)*pi/2;
for k = 1:4
    px = R*cos(ang(k))*0.85; py = R*sin(ang(k))*0.85;
    plot3(ax,[px px*1.5],[py py*1.5],[zb_top zb_top+0.55], ...
        '-','Color',[0.05 0.05 0.05],'LineWidth',1.5);
    plot3(ax,px,py,zb_top,'o','MarkerFaceColor',[0.7 0.7 0.7], ...
        'MarkerEdgeColor','k','MarkerSize',4);
end

% ----- antenna whip ----------------------------------------------
plot3(ax,[0 0],[0 0],[zb_top zb_top+0.50], ...
    '-','Color',[0.1 0.1 0.1],'LineWidth',2.0);
text(ax,0,0,zb_top+0.55,'\lambda/4 144.39 MHz', ...
    'HorizontalAlignment','center','FontSize',8);

% ----- optical port (PMMA disk at base) ---------------------------
zp = Hdom - 0.005;
[xpc,ypc,zpc] = cylinder(G.optical_port.OD_mm/2000, 30);
surf(ax, xpc, ypc, zpc*0.01 + zp, 'FaceColor',[0.85 0.95 1], ...
    'FaceAlpha',0.55,'EdgeColor','none');

end

% ------------------------------------------------------------------
function draw_internal_stack(ax, PE)
T = PE.mass_table;
for k = 1:height(T)
    nm = T.item{k};
    p  = T.pos_xyz_m{k};
    d  = T.dims_xyz_m{k};
    if startsWith(nm,'CF') || startsWith(nm,'XPS') || ...
       startsWith(nm,'Top truss') || startsWith(nm,'Bottom') || ...
       startsWith(nm,'CF retention') || startsWith(nm,'Optical') || ...
       startsWith(nm,'Bridle') || startsWith(nm,'1/4')
        continue
    end
    col = pick_color(nm);
    drawbox(ax, p-d/2, d, col);
    text(ax, p(1), p(2), p(3)+d(3)/2+0.01, nm, ...
        'FontSize',7,'HorizontalAlignment','center');
end
% CG marker
CG = PE.totals.CG_m;
plot3(ax,CG(1),CG(2),CG(3),'kp','MarkerSize',12,'MarkerFaceColor',[1 0.85 0]);
text(ax,CG(1),CG(2),CG(3)+0.01,'CG','FontWeight','bold','FontSize',8);
end

function drawbox(ax,p,d,col)
x=p(1); y=p(2); z=p(3); a=d(1); b=d(2); c=d(3);
V=[x y z;x+a y z;x+a y+b z;x y+b z;x y z+c;x+a y z+c;x+a y+b z+c;x y+b z+c];
F=[1 2 3 4;5 6 7 8;1 2 6 5;2 3 7 6;3 4 8 7;4 1 5 8];
patch(ax,'Vertices',V,'Faces',F,'FaceColor',col, ...
    'FaceAlpha',0.85,'EdgeColor',[0.15 0.15 0.15],'LineWidth',0.4);
end

function c = pick_color(nm)
c = [0.6 0.6 0.6];
if contains(nm,'APRS'),     c=[0.10 0.45 0.85]; end
if contains(nm,'Arduino'),  c=[0.55 0.10 0.65]; end
if contains(nm,'BMP') || contains(nm,'UV'), c=[0.95 0.65 0.10]; end
if contains(nm,'IMU'),      c=[0.10 0.30 0.85]; end
if contains(nm,'Geiger'),   c=[0.85 0.10 0.45]; end
if contains(nm,'CO2'),      c=[0.10 0.65 0.55]; end
if contains(nm,'PM'),       c=[0.45 0.55 0.20]; end
if contains(nm,'SHT'),      c=[0.55 0.85 0.85]; end
if contains(nm,'Energizer')||contains(nm,'AA'), c=[0.95 0.55 0.10]; end
if contains(nm,'BMS'),      c=[0.30 0.30 0.30]; end
if contains(nm,'SD'),       c=[0.20 0.20 0.20]; end
if contains(nm,'Hardware'), c=[0.7 0.7 0.7]; end
end

function rgb = hex2rgb(h)
h = strrep(h,'#','');
rgb = [hex2dec(h(1:2)) hex2dec(h(3:4)) hex2dec(h(5:6))]/255;
end
