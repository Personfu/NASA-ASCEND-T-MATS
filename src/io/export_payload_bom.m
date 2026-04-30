function export_payload_bom(PE, cfg)
%EXPORT_PAYLOAD_BOM  Write the as-flown bill-of-materials and
%   engineering summary for the Phoenix-1 payload (Personfu) into
%   reports/payload_bom.csv and reports/payload_engineering.md.

if ~exist(cfg.paths.reports,'dir'), mkdir(cfg.paths.reports); end

% CSV BOM
T = PE.mass_table;
csv = fullfile(cfg.paths.reports,'payload_bom.csv');
writetable(T, csv);
fprintf('  export_payload_bom     -> %s\n', csv);

% Markdown engineering summary
md = fullfile(cfg.paths.reports,'payload_engineering.md');
fid = fopen(md,'w');
c = onCleanup(@() fclose(fid));
fprintf(fid, '# %s  -  Engineering Summary\n\n', PE.name);
fprintf(fid, 'Designer: **%s** | Team: %s\n\n', PE.designer, PE.team);
fprintf(fid, '## Mass / CG / Inertia\n\n');
fprintf(fid, '- Total mass: **%.3f kg** (%.2f lb)\n', PE.totals.mass_kg, PE.totals.mass_kg*2.2046);
fprintf(fid, '- CG (m): [%.3f %.3f %.3f]\n', PE.totals.CG_m);
fprintf(fid, '- I_diag (kg m^2): [%.4f %.4f %.4f]\n\n', PE.totals.I_diag_kgm2);

fprintf(fid, '## Geometry\n\n');
G = PE.geometry;
fprintf(fid, '- Body OD x H: %.0f mm x %.0f mm\n', G.body_OD_mm, G.body_H_mm);
fprintf(fid, '- Skin: %.2f mm PETG-CF + %.2f mm 3K twill = %.2f mm total\n', ...
    G.wall_t_mm, G.cf_wrap_t_mm, G.skin_t_mm);
fprintf(fid, '- Cap height: %.0f mm (truss lattice)\n', G.cap_H_mm);
fprintf(fid, '- Bottom dome: %.0f mm with PMMA optical port (%.0f mm OD)\n\n', ...
    G.dome_H_mm, G.optical_port.OD_mm);

fprintf(fid, '## Structural margins\n\n');
fprintf(fid, '- Shock load (12 g): %.0f N axial\n', PE.loads.F_shock_N);
fprintf(fid, '- Buckling P_cr: %.0f N (MS = %.2f)\n', PE.loads.P_buckle_N, PE.loads.MS_buckle);
fprintf(fid, '- Hoop stress @ 5 kPa: %.2f MPa (MS = %.2f)\n\n', ...
    PE.loads.sigma_hoop_MPa, PE.loads.MS_hoop);

fprintf(fid, '## Thermal\n\n');
fprintf(fid, '- alpha_solar=%.2f, eps_LWIR=%.2f, UA_wall=%.3f W/K, tau=%.0f s, Q_int=%.2f W\n\n', ...
    PE.thermal.alpha_solar, PE.thermal.eps_LWIR, PE.thermal.UA_wall_W_K, ...
    PE.thermal.tau_thermal_s, PE.thermal.Q_internal_W);

fprintf(fid, '## Electrical\n\n');
fprintf(fid, '- 8x AA L91 / 12 V / %.1f Wh, avg %.2f W -> DoD %.1f%%\n\n', ...
    PE.electrical.bus_capacity_Wh, PE.electrical.avg_W, ...
    PE.electrical.depth_of_discharge*100);

fprintf(fid, '## Comms\n\n');
fprintf(fid, '- APRS %s @ %.3f MHz / %.1f W / %.1f dBi whip / beacon %.0f s\n\n', ...
    PE.comms.aprs.callsign, PE.comms.aprs.freq_MHz, PE.comms.aprs.tx_W, ...
    PE.comms.aprs.gain_dBi, PE.comms.aprs.beacon_s);

fprintf(fid, '## Mass table\n\n| Item | mass (g) |\n|---|---:|\n');
for k=1:height(T)
    fprintf(fid, '| %s | %d |\n', T.item{k}, T.mass_g{k});
end
fprintf('  export_payload_bom     -> %s\n', md);
end
