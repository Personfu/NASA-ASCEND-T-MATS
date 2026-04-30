function viz_aerodynamics(FD, cfg)
%VIZ_AERODYNAMICS  Aerodynamic regime dashboard for the ASCEND S26 flight.
%
%   Plots Mach, dynamic pressure, Reynolds number, and energy partitioning
%   versus altitude / time, plus a stability index from BMP390 lapse rate.

if isempty(FD), return; end
t = seconds(FD.Time)/60;
h = FD.alt_m/1000;

f = figure('Color','w','Units','pixels','Position',[60 60 1500 920],'Visible','off');
tiledlayout(f,3,2,'Padding','compact','TileSpacing','compact');

% Mach vs altitude
nexttile; plot(FD.Mach, h,'-','LineWidth',1.4); grid on;
xlabel('Mach'); ylabel('altitude (km)'); title('Free-stream Mach vs altitude');

% Dynamic pressure
nexttile; plot(t, FD.q_Pa,'-','LineWidth',1.4); grid on;
xlabel('T+ (min)'); ylabel('q (Pa)'); title('Dynamic pressure q(t)');

% Reynolds
nexttile; semilogx(FD.Re, h,'-','LineWidth',1.4); grid on;
xlabel('Re_{box} (-)'); ylabel('altitude (km)'); title('Reynolds number (L=0.30 m)');

% Energy partitioning
nexttile; hold on; grid on;
plot(t, FD.KE_J/1e3,'-','LineWidth',1.2);
plot(t, FD.PE_J/1e3,'-','LineWidth',1.2);
plot(t, FD.E_mech_J/1e3,'k-','LineWidth',1.6);
xlabel('T+ (min)'); ylabel('energy (kJ)');
legend('KE','PE','total','Location','best'); title('Mechanical energy budget');

% Brunt-Vaisala N^2 vs altitude
nexttile;
if any(~isnan(FD.N2_invs2))
    plot(FD.N2_invs2, h, '-','LineWidth',1.4); grid on;
    xlabel('N^2 (1/s^2)'); ylabel('altitude (km)');
    title('Atmospheric stability (N^2 from BMP390)');
else
    text(0.5,0.5,'No BMP390 data','HorizontalAlignment','center'); axis off;
end

% Free-lift residual during ascent
nexttile;
plot(t, FD.F_lift_N,'-','LineWidth',1.4); grid on;
xlabel('T+ (min)'); ylabel('F_{lift} - W - D (N)');
title('Ascent net force (>0 = climbing free-lift)');

sgtitle(f,'ASCEND S26 - Aerodynamic Regime','FontWeight','bold');

base = fullfile(cfg.paths.figures,'10_aerodynamics');
for k=1:numel(cfg.plot.export_formats)
    exportgraphics(f, [base,'.',cfg.plot.export_formats{k}],'Resolution',cfg.plot.dpi);
end
fprintf('  saved -> %s.{%s}\n', base, strjoin(cfg.plot.export_formats,','));
close(f);
end
