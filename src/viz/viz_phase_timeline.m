function viz_phase_timeline(D, E, FD, cfg)
%VIZ_PHASE_TIMELINE  Mission timeline visualization with annotated events.
%
%   Renders altitude vs time with vertical event markers (release,
%   stratosphere, tropopause, Armstrong limit, Pfotzer max, apex,
%   parachute stable, touchdown), shaded ascent/descent phase bands,
%   and an inset of dynamic pressure q(t).

T = D.trajectory;
tmin = T.t_s/60;

f = figure('Color','w','Units','pixels','Position',[60 60 1400 760],'Visible','off');
ax1 = subplot(3,1,[1 2]); hold on; grid on;

% phase bands
[apexA,iA] = max(T.alt_m);
patch([tmin(1) tmin(iA) tmin(iA) tmin(1)], ...
      [0 0 apexA*1.05 apexA*1.05], [0.85 0.92 1.0], 'EdgeColor','none','FaceAlpha',0.35);
patch([tmin(iA) tmin(end) tmin(end) tmin(iA)], ...
      [0 0 apexA*1.05 apexA*1.05], [1.0 0.88 0.85], 'EdgeColor','none','FaceAlpha',0.35);

% altitude trace
plot(tmin, T.alt_m, 'k-','LineWidth',1.6);

% events
ev = {'release','stratosphere','tropopause','armstrong','apex','pfotzer','parachute_ok','touchdown'};
col = lines(numel(ev));
for k=1:numel(ev)
    if ~isfield(E,ev{k}), continue; end
    s = E.(ev{k});
    if ~isfield(s,'alt_m') || isnan(s.alt_m), continue; end
    if isfield(s,'t_s') && ~isnan(s.t_s)
        xe = s.t_s/60;
    else
        % event tied to altitude only
        [~, ix] = min(abs(T.alt_m - s.alt_m));
        xe = tmin(ix);
    end
    xline(xe, '--', ev{k}, 'LineWidth',1.3, 'Color', col(k,:), ...
          'LabelOrientation','horizontal','LabelVerticalAlignment','top','FontSize',8);
    plot(xe, s.alt_m, 'o','MarkerFaceColor',col(k,:),'MarkerEdgeColor','k','MarkerSize',8);
end

xlabel('T+ (min)'); ylabel('altitude MSL (m)');
title(sprintf('Mission Timeline - apex %.0f m (%.0f ft) at T+%.1f min', ...
    apexA, apexA/0.3048, T.t_s(iA)/60));
legend({'ascent','descent','altitude'}, 'Location','best');

% dynamic pressure inset
ax2 = subplot(3,1,3); hold on; grid on;
if ~isempty(FD)
    plot(seconds(FD.Time)/60, FD.q_Pa, 'b-','LineWidth',1.4);
    [qmx, iq] = max(FD.q_Pa);
    plot(seconds(FD.Time(iq))/60, qmx, 'rp','MarkerSize',12,'MarkerFaceColor','r');
    text(seconds(FD.Time(iq))/60, qmx, sprintf('  q_{max}=%.0f Pa', qmx));
    ylabel('dyn pressure q (Pa)');
end
xlabel('T+ (min)');
title('Dynamic pressure profile');

base = fullfile(cfg.paths.figures,'09_phase_timeline');
for k=1:numel(cfg.plot.export_formats)
    exportgraphics(f, [base,'.',cfg.plot.export_formats{k}],'Resolution',cfg.plot.dpi);
end
fprintf('  saved -> %s.{%s}\n', base, strjoin(cfg.plot.export_formats,','));
close(f);
end
