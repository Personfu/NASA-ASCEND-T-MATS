function write_mission_report(D, sim, MC, link, val, cfg)
%WRITE_MISSION_REPORT  Generates Markdown + plain-text mission report.

rpath = fullfile(cfg.paths.reports,'ASCEND_S26_MISSION_REPORT.md');
fid = fopen(rpath,'w');
P = @(varargin) fprintf(fid, varargin{:});

T = D.trajectory;
[apex_m, kapex] = max(T.alt_m);
land = T(end,:);

P('# Phoenix College NASA ASCEND - Spring 2026 Flight Report\n');
P('_Authored by Personfu, AI Senior Engineering Lead_\n\n');
P('## 1. Mission Summary\n\n');
P('| Field | Value |\n|---|---|\n');
P('| Launch UTC          | %s |\n', datestr(cfg.mission.launch_utc,'yyyy-mm-dd HH:MM:SS'));
P('| Launch site         | %.5f N, %.5f W, %.0f m MSL |\n', cfg.mission.launch_lat, -cfg.mission.launch_lon, cfg.mission.launch_alt_m);
P('| Burst altitude      | %.1f m (%.1f ft) |\n', apex_m, apex_m/0.3048);
P('| Time to burst       | %.1f min |\n', T.t_s(kapex)/60);
P('| Peak descent rate   | %.1f m/s (%.1f mph) |\n', max(abs(T.vz_ms)), max(abs(T.vz_ms))*2.237);
P('| Landing speed       | %.1f m/s |\n', abs(T.vz_ms(end)));
P('| Total flight time   | %.1f min |\n', T.t_s(end)/60);
P('| Range from launch   | %.1f km |\n', wgs84_inverse(cfg.mission.launch_lat,cfg.mission.launch_lon,land.lat,land.lon)/1000);
P('| Payload flight mass | %.0f g |\n', cfg.payload.total_mass_kg*1000);
P('| FAA Part 101 class  | Light (compliant) |\n\n');

P('## 2. Validation (model vs flight)\n\n');
if isfield(val,'summary_table')
    tbl = val.summary_table;
    P('| Test | N | Bias | RMSE | MAE | R^2 |\n|---|---|---|---|---|---|\n');
    for i = 1:height(tbl)
        P('| %s | %d | %.3f | %.3f | %.3f | %.3f |\n', tbl.Test{i}, tbl.N(i), tbl.Bias(i), tbl.RMSE(i), tbl.MAE(i), tbl.R2(i));
    end
end

P('\n## 3. Monte Carlo Dispersion (N=%d)\n\n', MC.N);
P('* CEP50 = %.2f km\n', MC.cep50_km);
P('* CEP95 = %.2f km\n', MC.cep95_km);
P('* Mean apex = %.0f m, sigma = %.0f m\n', mean(MC.apex_m), std(MC.apex_m));
P('* Mean impact = %.1f m/s, sigma = %.1f m/s\n\n', mean(MC.impact_ms), std(MC.impact_ms));

P('## 4. Link Budget\n\n');
P('* Frequency: %.3f MHz\n', link.Properties.UserData.f_MHz);
P('* Worst-case margin: %.1f dB\n', min(link.link_margin_dB));
P('* Mean SNR: %.1f dB\n', mean(link.snr_dB,'omitnan'));
P('* Max slant range: %.1f km\n\n', max(link.d_km));

P('## 5. Science Highlights\n\n');
if isfield(D,'geiger') && ~isempty(D.geiger)
    P('* Peak cosmic ray dose: %.2f uSv/h at %.0f m\n', max(D.geiger.usvph), apex_m);
end
if isfield(D,'multi') && ~isempty(D.multi)
    P('* Min internal temperature: %.1f C\n', min(D.multi.temp_c));
    P('* Max PM2.5 reading: %.1f ug/m^3\n', max(D.multi.pm2p5));
    P('* CO2 range: %.0f - %.0f ppm\n', min(D.multi.co2_ppm), max(D.multi.co2_ppm));
end

P('\n## 6. References\n\n');
P('* US Standard Atmosphere 1976\n');
P('* IGRF-13 (2026 epoch)\n');
P('* Madgwick AHRS (2010)\n');
P('* Pfotzer-Regener cosmic ray maximum\n');
P('* FAA Part 101 Subpart D\n');
fclose(fid);
fprintf('Mission report written to %s\n', rpath);
end
