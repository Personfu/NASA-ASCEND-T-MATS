function R = model_uv_ozone(cfg, alt_m, t_utc)
%MODEL_UV_OZONE  Beer-Lambert UV irradiance through ozone column.
%
%   R = MODEL_UV_OZONE(cfg, alt_m, t_utc) computes UVA, UVB, UVC at
%   payload altitude using top-of-atmosphere irradiance, slant-path
%   ozone column above, Rayleigh scattering and air-mass m(theta_z)
%   from Kasten-Young.
%
%   I(lam,h) = I0(lam) * exp( -tau_O3(lam)*N_O3(h)*m - tau_R(lam,h)*m )
%
%   where ozone column above altitude follows a Chapman profile centered
%   at 22 km.  Total column is cfg.science.ozone_col_DU.

if isempty(alt_m), R=table; return; end
n = numel(alt_m);

if nargin<3 || isempty(t_utc)
    t_utc = repmat(cfg.mission.launch_time_utc,n,1);
elseif numel(t_utc)==1
    t_utc = repmat(t_utc,n,1);
end

% Bands (centroid wavelengths nm) and TOA irradiance (W/m^2) approx
bands = struct('UVC',[260, 0.05], 'UVB',[300, 0.55], 'UVA',[365, 4.20]);
% Ozone absorption cross-section (cm^2 / molecule)
% Hartley/Huggins peaks: 255 nm 1.13e-17, 300 nm 3.5e-19, 365 nm 1e-23
sigma_O3 = struct('UVC',1.13e-17, 'UVB',3.5e-19, 'UVA',1e-23);

% Ozone column above altitude h (DU). Chapman cumulative:
%   N(h) = N_total * 0.5 * erfc( (h - h0)/H )   with h0=22 km, H=8 km
N_total_DU = cfg.science.ozone_col_DU;
h0 = 22000; Hsc = 8000;
N_above_DU = N_total_DU .* 0.5 .* erfc((alt_m - h0)./Hsc);
% 1 DU = 2.69e16 molec/cm^2
N_above = N_above_DU(:) * 2.69e16;

% Solar zenith
sz = arrayfun(@(t) solar_zenith(t, cfg.mission.launch_lat, cfg.mission.launch_lon), t_utc(:));
% Kasten-Young air mass
m = 1 ./ (cos(deg2rad(sz)) + 0.50572.*(96.07995 - sz).^(-1.6364));
m(sz>=90) = NaN;

% Pressure for Rayleigh scaling
[~,P,~] = atm_us1976(alt_m);
P_ratio = P(:)/101325;

UVA = bands.UVA(2)*ones(n,1);
UVB = bands.UVB(2)*ones(n,1);
UVC = bands.UVC(2)*ones(n,1);
for i=1:n
    if isnan(m(i)), UVA(i)=0; UVB(i)=0; UVC(i)=0; continue; end
    tau_R_uvA = 0.10*P_ratio(i)*(550/365)^4;
    tau_R_uvB = 0.10*P_ratio(i)*(550/300)^4;
    tau_R_uvC = 0.10*P_ratio(i)*(550/260)^4;
    UVA(i) = bands.UVA(2)*exp(-(sigma_O3.UVA*N_above(i) + tau_R_uvA)*m(i));
    UVB(i) = bands.UVB(2)*exp(-(sigma_O3.UVB*N_above(i) + tau_R_uvB)*m(i));
    UVC(i) = bands.UVC(2)*exp(-(sigma_O3.UVC*N_above(i) + tau_R_uvC)*m(i));
end

% Convert W/m^2 -> mW/cm^2
UVA_mWcm2 = UVA*0.1; UVB_mWcm2 = UVB*0.1; UVC_mWcm2 = UVC*0.1;

R = timetable(seconds((1:n)'), alt_m(:), sz(:), m(:), N_above_DU(:), UVA_mWcm2, UVB_mWcm2, UVC_mWcm2, ...
    'VariableNames',{'alt_m','solar_zen_deg','airmass','O3_above_DU','UVA_mWcm2','UVB_mWcm2','UVC_mWcm2'});
R.Properties.DimensionNames{1}='idx';
end

function sz_deg = solar_zenith(dt_utc, lat, lon)
doy = day(dt_utc,'dayofyear');
gamma = 2*pi/365 * (doy - 1 + (hour(dt_utc)-12)/24);
decl = 0.006918 - 0.399912*cos(gamma) + 0.070257*sin(gamma) ...
       - 0.006758*cos(2*gamma) + 0.000907*sin(2*gamma) ...
       - 0.002697*cos(3*gamma) + 0.00148*sin(3*gamma);
eqt = 229.18*(0.000075 + 0.001868*cos(gamma) - 0.032077*sin(gamma) ...
       - 0.014615*cos(2*gamma) - 0.040849*sin(2*gamma));
tst = mod(hour(dt_utc)*60 + minute(dt_utc) + second(dt_utc)/60 + eqt + 4*lon, 1440);
ha  = deg2rad(tst/4 - 180);
phi = deg2rad(lat);
cosZ = sin(phi)*sin(decl) + cos(phi)*cos(decl)*cos(ha);
sz_deg = rad2deg(acos(max(min(cosZ,1),-1)));
end
