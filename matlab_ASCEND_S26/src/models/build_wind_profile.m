function W = build_wind_profile(D, cfg)
%BUILD_WIND_PROFILE  Data-driven horizontal wind field U(h), V(h).
%
%   W = BUILD_WIND_PROFILE(D, cfg) takes the ingested data and returns a
%   struct with the layered atmosphere wind profile derived from the
%   actual flown trajectory using Vincenty inverse between consecutive
%   APRS fixes:
%
%       wind speed    : ds/dt   (m/s)
%       wind heading  : forward azimuth (deg, met "from" convention)
%       u (eastward)  : V*sin(heading_to_deg)
%       v (northward) : V*cos(heading_to_deg)
%
%   The track is binned by altitude (200 m bins) and the ASCENT segment
%   is used as the column profile (the descent reflects the same air
%   mass with different displacement so we keep both for cross-check).
%
%   Output fields:
%     W.h_m        bin-center altitude (m MSL)
%     W.U_ms,V_ms  ENU wind components
%     W.spd_ms     scalar speed
%     W.dir_to_deg met "to" direction
%     W.dir_from_deg met "from" direction (where wind comes from)
%     W.profile    function handle  [u,v] = profile(h_m)
%     W.layers     N x 5 [h_low h_high U V spd]   (for tabular display)

T = D.trajectory;
isAsc = T.phase == "ascent" | T.phase == "launch";
Tasc = T(isAsc,:);

n = height(Tasc);
[u, v, spd, az_to] = deal(nan(n,1));

for i = 2:n
    [d, az, ~] = wgs84_inverse(Tasc.lat(i-1), Tasc.lon(i-1), Tasc.lat(i), Tasc.lon(i));
    dt = Tasc.t_s(i) - Tasc.t_s(i-1);
    if dt > 0
        spd(i)   = d/dt;                                  % m/s
        az_to(i) = az;                                    % deg from north (to)
        u(i)     = spd(i)*sind(az);                       % east
        v(i)     = spd(i)*cosd(az);                       % north
    end
end

% Bin by altitude (200 m bins from launch to apex)
hmin = min(Tasc.alt_m); hmax = max(Tasc.alt_m);
edges = (floor(hmin/200)*200 : 200 : ceil(hmax/200)*200)';
[~,~,bin] = histcounts(Tasc.alt_m, edges);
nb = numel(edges)-1;
[Ub, Vb, Sb, Hb] = deal(nan(nb,1));
for k = 1:nb
    idx = bin == k;
    if any(idx)
        Ub(k) = mean(u(idx),'omitnan');
        Vb(k) = mean(v(idx),'omitnan');
        Sb(k) = mean(spd(idx),'omitnan');
        Hb(k) = (edges(k)+edges(k+1))/2;
    end
end
ok = ~isnan(Ub) & ~isnan(Vb);
Ub=Ub(ok); Vb=Vb(ok); Sb=Sb(ok); Hb=Hb(ok);

dir_to   = mod(atan2d(Ub,Vb),360);
dir_from = mod(dir_to+180,360);

W.h_m         = Hb;
W.U_ms        = Ub;
W.V_ms        = Vb;
W.spd_ms      = Sb;
W.dir_to_deg  = dir_to;
W.dir_from_deg= dir_from;
W.layers      = [edges(ok), edges([false; ok]), Ub, Vb, Sb];
W.note        = 'Wind profile derived from APRS-only ascent leg (Vincenty)';

% Smooth interpolant
W.profile = @(h) interp_uv(h, Hb, Ub, Vb);

cache = fullfile(cfg.paths.data_proc, 'wind_profile.mat');
save(cache, 'W');
end

function [u,v] = interp_uv(h, Hb, Ub, Vb)
u = interp1(Hb, Ub, h, 'linear', 'extrap');
v = interp1(Hb, Vb, h, 'linear', 'extrap');
end
