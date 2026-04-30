function R = model_cosmic_ray(cfg, alt_m)
%MODEL_COSMIC_RAY  Pfotzer-Regener secondary cosmic-ray dose vs altitude.
%
%   R = MODEL_COSMIC_RAY(cfg, alt_m) evaluates a parametric Pfotzer-
%   Regener curve calibrated against the GMC-320+ flight data.  The
%   secondary particle flux peaks at 18-22 km (atmospheric depth
%   ~70-90 g/cm^2) and decays as primaries are unobstructed above and
%   absorbed below.
%
%   Implementation: log-normal of atmospheric depth X(h) using
%   US-1976 pressure, scaled to deliver
%       D(0) = bg, D(peak) = peak  in uSv/h, with 33 N geomagnetic
%       cutoff rigidity ~= 4.5 GV.
%
%   Returns timetable: alt_m, X_g_cm2, dose_uSvph, cpm_pred, particles_pred.

if isempty(alt_m), R=table; return; end
[~,P,~] = atm_us1976(alt_m);
X = P/9.80665/10;     % g/cm^2  (mass column of air above)

X_peak = 75;          % g/cm^2  Pfotzer
sigma  = 0.55;        % log-normal width
bg     = cfg.science.cosmic_ray_bg_uSvph;
peak   = cfg.science.pfotzer_peak_uSvph;

f = @(x) exp(-0.5*(log(x/X_peak)/sigma).^2);
norm = 1 - bg/peak;
dose = bg + norm*peak*f(X);

% At extreme altitudes (>30 km) atmospheric depth -> small, dose -> ~peak/2
% (galactic primaries in free space).
dose(X<5) = dose(X<5).*0.5 + 0.5*peak*0.55;

% CPM correlation: GMC-320+ ~120 cpm/uSv-h
cpm = dose*120;
particles = cpm/60;       % counts/s

R = timetable(seconds((1:numel(alt_m))'), alt_m(:), X(:), dose(:), cpm(:), particles(:), ...
    'VariableNames',{'alt_m','X_g_cm2','dose_uSvph','cpm_pred','particles_per_s'});
R.Properties.DimensionNames{1}='idx';
end
