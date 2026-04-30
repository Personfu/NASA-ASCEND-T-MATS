function rep = validation_suite(D, sim, cfg)
%VALIDATION_SUITE  Quantitative comparison of model vs flight data.
%
%   rep = VALIDATION_SUITE(D, sim, cfg) computes residuals, RMSE, R^2,
%   and bias for:
%     1. BMP390 baro-altitude vs APRS GPS altitude
%     2. Simulated ascent altitude vs APRS altitude
%     3. Simulated descent vs APRS altitude
%     4. US-1976 temperature vs BMP390 temperature
%     5. Pfotzer-Regener cosmic ray model vs Geiger CPM (binned by alt)
%     6. UV ozone model vs averaged UVA/UVB sensor (vs alt)

rep = struct(); 
T = D.trajectory; 
A = D.arduino;

% --- 1) BMP390 altitude vs APRS altitude
if ismember('alt_baro_m', A.Properties.VariableNames)
    tA = seconds(A.Properties.RowTimes - A.Properties.RowTimes(1));
    tT = T.t_s;
    aprs_at_A = interp1(tT, T.alt_m, tA, 'linear','extrap');
    rep.bmp_vs_aprs = stats_pair(aprs_at_A, A.alt_baro_m);
end

% --- 2) sim ascent vs flight
if isfield(sim,'ascent3d') && ~isempty(sim.ascent3d)
    s = sim.ascent3d;
    ts = seconds(s.Properties.RowTimes);
    flight_at_s = interp1(T.t_s, T.alt_m, ts, 'linear','extrap');
    rep.ascent_sim = stats_pair(flight_at_s, s.x_U);
elseif isfield(sim,'ascent') && ~isempty(sim.ascent)
    s = sim.ascent;
    flight_at_s = interp1(T.t_s, T.alt_m, s.t_s,'linear','extrap');
    rep.ascent_sim = stats_pair(flight_at_s, s.alt_m);
end

% --- 3) descent
if isfield(sim,'descent3d') && ~isempty(sim.descent3d)
    s = sim.descent3d;
    ts = seconds(s.Properties.RowTimes) + s.Properties.UserData.t0;
    flight_at_s = interp1(T.t_s, T.alt_m, ts, 'linear','extrap');
    rep.descent_sim = stats_pair(flight_at_s, s.x_U);
end

% --- 4) US-1976 temp vs BMP390 temp
if ismember('temp_c', A.Properties.VariableNames) && ismember('alt_baro_m',A.Properties.VariableNames)
    [Tatm,~,~,~,~] = arrayfun(@atm_us1976, A.alt_baro_m);
    rep.temp_atm = stats_pair(Tatm-273.15, A.temp_c);
end

% --- 5) cosmic ray model vs Geiger
if isfield(D,'geiger') && ~isempty(D.geiger)
    G = D.geiger;
    tG = seconds(G.Properties.RowTimes - T.Properties.RowTimes(1));
    altG = interp1(T.t_s, T.alt_m, tG, 'linear','extrap');
    cr = model_cosmic_ray(altG);
    rep.cosmic_ray = stats_pair(cr.cpm, G.cpm);
end

rep.summary_table = build_summary(rep);
end

function s = stats_pair(ref, sig)
ok = isfinite(ref) & isfinite(sig);
ref = ref(ok); sig = sig(ok);
res = sig - ref;
s.RMSE = sqrt(mean(res.^2));
s.bias = mean(res);
s.MAE  = mean(abs(res));
SS_res = sum(res.^2);
SS_tot = sum((ref-mean(ref)).^2);
s.R2   = 1 - SS_res/max(SS_tot,eps);
s.N    = numel(ref);
end

function tbl = build_summary(rep)
fn = fieldnames(rep); fn(strcmp(fn,'summary_table'))=[];
rows = {};
for k = 1:numel(fn)
    s = rep.(fn{k});
    rows(end+1,:) = {fn{k}, s.N, s.bias, s.RMSE, s.MAE, s.R2}; %#ok<AGROW>
end
tbl = cell2table(rows,'VariableNames',{'Test','N','Bias','RMSE','MAE','R2'});
end
