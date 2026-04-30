function E = detect_flight_events(D, cfg)
%DETECT_FLIGHT_EVENTS  Phase / event detection for the ASCEND S26 mission.
%
%   E = DETECT_FLIGHT_EVENTS(D, cfg) returns a struct with annotated
%   transitions extracted from the APRS trajectory:
%       E.release       - first positive vertical velocity, treated as launch
%       E.tropopause    - altitude where dT/dh ~ 0 (BMP390 lapse-rate inflection)
%       E.stratosphere  - first crossing of 11 km
%       E.armstrong     - first crossing of 19 km (Armstrong limit, 6.3 kPa)
%       E.pfotzer       - altitude band of cosmic-ray dose maximum
%       E.apex          - max-altitude (burst) sample
%       E.parachute_ok  - first descent v stable < 25 m/s after burst
%       E.touchdown     - last sample before alt within +/-50 m of launch alt
%       E.flight_phases - timetable of {ascent | float | descent | recovered}
%
%   All times are referenced to seconds since launch (T.t_s).

T = D.trajectory;
G = D.geiger;
A = D.arduino;

% ---- release: first sample with v_z > 0.5 m/s
iRel = find(T.vz_ms > 0.5, 1, 'first');
if isempty(iRel), iRel = 1; end
E.release = pack_event(T, iRel, 'Release / launch');

% ---- apex
[apex_m, iApex] = max(T.alt_m);
E.apex = pack_event(T, iApex, sprintf('Burst / apex (%.0f ft)', apex_m/0.3048));

% ---- stratosphere boundary (11 km)
iStr = find(T.alt_m >= 11000 & T.t_s <= T.t_s(iApex), 1, 'first');
if ~isempty(iStr), E.stratosphere = pack_event(T, iStr, 'Stratosphere (11 km)'); end

% ---- Armstrong limit (19 km)
iArm = find(T.alt_m >= 19000 & T.t_s <= T.t_s(iApex), 1, 'first');
if ~isempty(iArm), E.armstrong = pack_event(T, iArm, 'Armstrong limit (19 km)'); end

% ---- tropopause via BMP390 lapse-rate inflection (smooth, then dT/dh -> 0)
E.tropopause = struct('t_s',NaN,'alt_m',NaN,'lat',NaN,'lon',NaN,'desc','n/a');
if ~isempty(A) && all(ismember({'alt_baro_m','temp_C'}, A.Properties.VariableNames))
    h = A.alt_baro_m; T_C = A.temp_C;
    msk = ~isnan(h) & ~isnan(T_C) & h>2000;
    if nnz(msk)>50
        h = h(msk); Tc = T_C(msk);
        [hs, idx] = sort(h); Ts = Tc(idx);
        % bin every 250 m and average
        edges = (floor(min(hs)/250)*250):250:(ceil(max(hs)/250)*250);
        bc = movmean(Ts, 25);
        % find first altitude > 8 km where T stops decreasing (dT/dh >= 0)
        dTdh = [0; diff(bc)./max(diff(hs),1)];
        cand = find(hs>8000 & hs<20000 & dTdh > -0.0005, 1, 'first');
        if ~isempty(cand)
            E.tropopause = struct('t_s',NaN,'alt_m',hs(cand), ...
                'lat',NaN,'lon',NaN, ...
                'desc',sprintf('Tropopause (lapse->0 at %.0f m, T=%.1f C)', hs(cand), Ts(cand)));
        end
    end
end

% ---- Pfotzer maximum: altitude band where dose rate is maximum
E.pfotzer = struct('alt_m',NaN,'dose_uSvph',NaN,'desc','n/a');
if ~isempty(G) && height(G)>10
    % match each Geiger sample to nearest trajectory altitude by time
    g_t = seconds(G.Time - cfg.mission.launch_time_utc);
    msk = g_t>=0 & g_t<=max(T.t_s);
    if any(msk)
        h_at_g = interp1(T.t_s, T.alt_m, g_t(msk), 'linear', NaN);
        d = G.dose_uSvph(msk);
        edges = 0:1000:30000;
        [~,~,bin] = histcounts(h_at_g, edges);
        ub = unique(bin); ub(ub==0)=[];
        m = accumarray(bin(bin>0), d(bin>0), [], @(x)mean(x,'omitnan'));
        cnt = accumarray(bin(bin>0), 1);
        m(cnt<3) = NaN;
        [pkv, kk] = max(m);
        if ~isnan(pkv)
            E.pfotzer = struct('alt_m', edges(kk)+500, 'dose_uSvph', pkv, ...
                'desc', sprintf('Pfotzer max (%.2f uSv/h @ %.1f km)', pkv, (edges(kk)+500)/1000));
        end
    end
end

% ---- parachute stabilized descent (after apex, v steadily < 25 m/s for 30 s)
E.parachute_ok = struct('t_s',NaN,'alt_m',NaN,'desc','n/a');
post = (1:height(T))' > iApex;
v = abs(T.vz_ms);
ok = post & v < 25;
% require 30 s sustained
runs = ones(size(ok));
for k=2:numel(ok), if ok(k), runs(k)=runs(k-1)+1; else, runs(k)=0; end, end
iPar = find(runs >= 5, 1, 'first');   % ~5 APRS fixes ~ 30+ s
if ~isempty(iPar), E.parachute_ok = pack_event(T, iPar, 'Parachute stabilized'); end

% ---- touchdown
launch_alt = cfg.mission.launch_alt_m;
iTd = find(T.alt_m <= launch_alt+150 & (1:height(T))' > iApex, 1, 'first');
if isempty(iTd), iTd = height(T); end
E.touchdown = pack_event(T, iTd, 'Touchdown / recovery');

% ---- phase timetable
phase = strings(height(T),1);
phase(1:iApex)            = "ascent";
phase((iApex+1):iTd)      = "descent";
phase((iTd+1):end)        = "recovered";
E.flight_phases = timetable(seconds(T.t_s), phase, 'VariableNames',{'phase'});

% ---- summary table
names = {'release','stratosphere','tropopause','armstrong','apex','pfotzer','parachute_ok','touchdown'};
rows = {};
for k=1:numel(names)
    n = names{k};
    if isfield(E,n)
        s = E.(n);
        rows(end+1,:) = {n, getf(s,'t_s'), getf(s,'alt_m'), getf(s,'desc')}; %#ok<AGROW>
    end
end
E.summary_table = cell2table(rows, 'VariableNames',{'event','t_s','alt_m','description'});
end

function s = pack_event(T, idx, desc)
s = struct('t_s',T.t_s(idx),'alt_m',T.alt_m(idx),'lat',T.lat(idx),'lon',T.lon(idx),'idx',idx,'desc',desc);
end
function v = getf(s,f), if isfield(s,f) && ~isempty(s.(f)), v=s.(f); else, v=NaN; end, end
