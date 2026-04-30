function MC = monte_carlo_dispersion(cfg, wind, N)
%MONTE_CARLO_DISPERSION  Landing dispersion ellipse from input uncertainty.
%
%   MC = MONTE_CARLO_DISPERSION(cfg, wind, N) runs N Monte Carlo trials
%   sampling:
%       - Helium fill volume    : V0 ~ N(V0, sigma=2%)
%       - Payload mass          : m  ~ N(m, sigma=1%)
%       - Parachute Cd          : Cd ~ N(1.5, sigma=0.10)
%       - Wind speed scale      : k  ~ N(1.00, sigma=0.15)
%       - Wind direction bias   : db ~ N(0, sigma=8 deg)
%       - Burst altitude        : hb ~ N(burst, sigma=1.5 km)
%
%   Returns structure with landing E,N (km), CEP50, CEP95, and ellipse.

if nargin < 3, N = 200; end
rng(20260328);

cfg0 = cfg; wind0 = wind;
land = zeros(N,2);  apex = zeros(N,1);  vimp = zeros(N,1);

for i = 1:N
    cfgi = cfg0;
    cfgi.balloon.fill_volume_m3 = cfg0.balloon.fill_volume_m3 * (1+0.02*randn);
    cfgi.payload.total_mass_kg  = cfg0.payload.total_mass_kg  * (1+0.01*randn);
    cfgi.parachute.cd           = max(0.8, 1.5+0.10*randn);
    cfgi.mission.burst_alt_m    = cfg0.mission.burst_alt_m + 1500*randn;

    k_w = 1 + 0.15*randn; db = 8*randn;
    Rz  = [cosd(db) -sind(db); sind(db) cosd(db)];
    windi = wind0;
    UV = (Rz*[wind0.U_ms.';wind0.V_ms.']).' * k_w;
    windi.U_ms = UV(:,1); windi.V_ms = UV(:,2);
    windi.profile = @(h) deal(interp1(wind0.h_m,UV(:,1),h,'linear','extrap'), ...
                              interp1(wind0.h_m,UV(:,2),h,'linear','extrap'));

    A = simulate_3d_ascent(cfgi, windi);
    apex(i) = A.x_U(end);
    x0 = [A.x_E(end), A.x_N(end), A.x_U(end)];
    v0 = [A.v_E(end), A.v_N(end), A.v_U(end)];
    Dsim = simulate_3d_descent(cfgi, windi, x0, v0);
    land(i,:) = [Dsim.x_E(end), Dsim.x_N(end)]/1000;
    vimp(i)   = Dsim.Properties.UserData.impact_v_ms;
end

mu  = mean(land,1);
C   = cov(land);
[V_, Lm] = eig(C);
ang = atan2d(V_(2,2), V_(1,2));
sx  = sqrt(Lm(1,1)); sy = sqrt(Lm(2,2));
r   = sqrt(sum((land-mu).^2,2));
MC.land_km   = land;
MC.mean_km   = mu;
MC.cov_km2   = C;
MC.cep50_km  = prctile(r,50);
MC.cep95_km  = prctile(r,95);
MC.ellipse_axes = [sx, sy];
MC.ellipse_ang  = ang;
MC.apex_m    = apex;
MC.impact_ms = vimp;
MC.N         = N;
end
