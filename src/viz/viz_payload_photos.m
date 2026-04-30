function viz_payload_photos(PS, cfg)
%VIZ_PAYLOAD_PHOTOS  Image-backed payload assembly reference sheet.
%
%   Builds a 2x3 photo gallery (engineering, flight unit, geiger,
%   feature shot, branding) overlaid with subsystem callouts derived
%   from payload_systems(). This is the "what is in the box" deck.
%
%   Output:  figures/11_payload_photos.png|pdf

if nargin < 2 || ~isfield(cfg.paths,'assets_imgs'); return; end
A = cfg.paths.assets_imgs;
spec = { ...
    fullfile(A,'Payload_Spring_2026.jpg'),  'Spring 2026 flight unit',  'flight';
    fullfile(A,'Payload_Engineering.png'),  'Engineering reference',     'engineering';
    fullfile(A,'PAYLOAD2025FEATURE.jpeg'),  'Heritage payload (Fa25)',   'heritage';
    fullfile(A,'GeigerCounter.jpeg'),       'GMC-320+ Geiger module',    'geiger';
    fullfile(A,'PCASCEND.png'),             'Phoenix College ASCEND',    'logo';
    fullfile(A,'spring2026','CO2_vs_altitude.png'), 'CO_2 vs altitude (web)','plot' };

f = figure('Color','w','Position',[60 60 1500 950],'Name','Payload Photo Gallery');
tl = tiledlayout(f,2,3,'TileSpacing','compact','Padding','compact');
title(tl,sprintf('%s  -  Payload Reference Gallery (Personfu)', cfg.mission.name), ...
      'FontWeight','bold','FontSize',13);

for k = 1:size(spec,1)
    nexttile;
    p = spec{k,1};
    if isfile(p)
        try
            img = imread(p);
            imshow(img,'Border','tight'); hold on
        catch
            text(0.5,0.5,'image read failed','Units','normalized','HorizontalAlignment','center');
        end
    else
        text(0.5,0.5,sprintf('missing\n%s',spec{k,1}), ...
             'Units','normalized','HorizontalAlignment','center','Interpreter','none');
        axis off
    end
    title(spec{k,2},'FontWeight','bold','FontSize',11);
end

% subsystem footer
nexttile(tl, 4); hold on
if nargin>=1 && isfield(PS,'totals')
    txt = sprintf(['Subsystems\n' ...
        '  tracker   %.0f g\n  multi     %.0f g\n  arduino   %.0f g\n' ...
        '  geiger    %.0f g\n  battery   %.0f g\n  parachute %.0f g\n' ...
        'Total mass %.2f kg'], ...
        PS.tracker.mass_g, PS.multi.mass_g, PS.arduino.mass_g, ...
        PS.geiger.mass_g, PS.power.mass_g, PS.parachute.mass_g, ...
        PS.totals.mass_kg);
    annotation(f,'textbox',[0.345 0.04 0.32 0.07],'String',txt, ...
        'FontName','Consolas','FontSize',9,'EdgeColor','k', ...
        'BackgroundColor',[1 1 1 0.85],'FitBoxToText','on');
end

out = fullfile(cfg.paths.figures,'11_payload_photos');
exportgraphics(f,[out '.png'],'Resolution',cfg.plot.dpi);
exportgraphics(f,[out '.pdf'],'ContentType','vector');
fprintf('  viz_payload_photos -> %s.{png,pdf}\n', out);
end
