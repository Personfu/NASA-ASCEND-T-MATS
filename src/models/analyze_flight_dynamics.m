function FD = analyze_flight_dynamics(D, cfg)
%ANALYZE_FLIGHT_DYNAMICS  Aerodynamic and energetic analysis along the trajectory.
%
%   FD = ANALYZE_FLIGHT_DYNAMICS(D, cfg) computes time series of:
%       - atmospheric state from US-1976 (rho, P, T, a)
%       - dynamic pressure q = 0.5 rho V^2 (descent + ascent)
%       - free-stream Mach
%       - Reynolds number based on payload box length
%       - vertical wind shear |dV/dh| from the windspeed sheet
%       - ascent free-lift residual (buoyancy - weight - drag)
%       - kinetic, potential and total mechanical energy
%       - Brunt-Vaisala frequency from BMP390 lapse rate (atmospheric stability)
%
%   The output is a timetable with one row per APRS fix plus a UserData
%   summary struct of bulk metrics.

T = D.trajectory;
n = height(T);
g0 = cfg.atm.g0;

% atmosphere along path (use APRS altitude)
[Ta, Pa, rho, a, mu] = arrayfun(@(h) atm_us1976(h), T.alt_m);

% velocity magnitudes
vz = T.vz_ms;
v = abs(vz);                      % vertical-only proxy when ground speed is sparse
if any(~isnan(T.gs_mph))
    gs_ms = T.gs_mph * 0.44704;
    v_total = sqrt(gs_ms.^2 + vz.^2);
    v_total(isnan(v_total)) = v(isnan(v_total));
else
    v_total = v;
end

% dynamic pressure / Mach / Re
q_Pa     = 0.5 .* rho .* v_total.^2;
Mach     = v_total ./ a;
L_ref    = 0.30;                  % box edge length
Re       = rho .* v_total .* L_ref ./ mu;

% mass: balloon expanded volume (ascent) or none (descent)
m_total  = (cfg.balloon.mass_kg + cfg.payload.total_mass_kg) * ones(n,1);
[~, iA]  = max(T.alt_m);
m_total(iA+1:end) = cfg.payload.total_mass_kg + 0.10;  % chute + line

% energies (potential ref = launch alt)
h_ref = cfg.mission.launch_alt_m;
KE = 0.5 .* m_total .* v_total.^2;
PE = m_total .* g0 .* (T.alt_m - h_ref);
E_mech = KE + PE;

% Brunt-Vaisala N^2 from BMP390 if present (stability index)
N2 = nan(n,1);
if isfield(D,'arduino') && ~isempty(D.arduino) && all(ismember({'alt_baro_m','temp_C'}, D.arduino.Properties.VariableNames))
    A = D.arduino;
    h = A.alt_baro_m; Tc = A.temp_C;
    msk = ~isnan(h) & ~isnan(Tc);
    h = h(msk); Tc = Tc(msk);
    [h, ix] = unique(h); Tc = Tc(ix);
    if numel(h)>20
        Tk = Tc + 273.15;
        Gamma_d = g0 / 1004.0;          % dry adiabatic lapse rate (K/m)
        dTdh = gradient(Tk, h);
        N2_h = (g0 ./ Tk) .* (dTdh + Gamma_d);
        N2 = interp1(h, N2_h, T.alt_m, 'linear', NaN);
    end
end

% wind shear from windspeed sheet
shear = nan(n,1);
if isfield(D,'wind') && ~isempty(D.wind)
    W = D.wind;
    if all(ismember({'alt_m','vlat_ms'}, W.Properties.VariableNames))
        h = W.alt_m; vw = W.vlat_ms;
        msk = ~isnan(h) & ~isnan(vw);
        h = h(msk); vw = vw(msk);
        [h, ix] = unique(h); vw = vw(ix);
        if numel(h)>5
            shear_h = abs(gradient(vw, h));
            shear = interp1(h, shear_h, T.alt_m, 'linear', NaN);
        end
    end
end

% ascent free-lift residual (buoyancy - weight - drag) - proxy
F_buoy = rho .* g0 .* cfg.balloon.fill_volume_m3;
W_grav = (cfg.balloon.mass_kg + cfg.payload.total_mass_kg) * g0;
F_drag = 0.5 .* rho .* v_total.^2 .* cfg.balloon.cd .* (pi*(cfg.balloon.burst_diam_m/2)^2/4);
F_res  = F_buoy - W_grav - F_drag;
F_res(iA+1:end) = NaN;  % only meaningful during ascent

% pack
FD = timetable(seconds(T.t_s), T.alt_m, v_total, rho, Pa, Ta, a, mu, ...
               q_Pa, Mach, Re, KE, PE, E_mech, N2, shear, F_res, ...
    'VariableNames', {'alt_m','v_ms','rho','P_Pa','T_K','a_ms','mu', ...
                      'q_Pa','Mach','Re','KE_J','PE_J','E_mech_J', ...
                      'N2_invs2','shear_inv_s','F_lift_N'});

FD.Properties.VariableUnits = {'m','m/s','kg/m^3','Pa','K','m/s','Pa s', ...
    'Pa','-','-','J','J','J','1/s^2','1/s','N'};

% bulk metrics
ud.q_max_Pa    = max(q_Pa,[],'omitnan');
ud.q_max_when  = T.t_s(find(q_Pa==ud.q_max_Pa,1,'first'));
ud.M_max       = max(Mach,[],'omitnan');
ud.Re_max      = max(Re,[],'omitnan');
ud.E_max_J     = max(E_mech,[],'omitnan');
ud.PE_apex_J   = PE(iA);
ud.shear_max   = max(shear,[],'omitnan');
FD.Properties.UserData = ud;

fprintf('  q_max = %.1f Pa @ T+%.0f s | M_max = %.3f | Re_max = %.2e\n', ...
    ud.q_max_Pa, ud.q_max_when, ud.M_max, ud.Re_max);
fprintf('  Apex PE = %.0f kJ | E_mech_max = %.0f kJ\n', ud.PE_apex_J/1e3, ud.E_max_J/1e3);
end
