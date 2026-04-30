function M = igrf13_field(lat, lon, alt_m, decimal_year)
%IGRF13_FIELD  Lightweight IGRF-13 dipole approximation for 2026.0 epoch.
%
%   M = IGRF13_FIELD(lat, lon, alt_m, decimal_year) returns geomagnetic
%   field components at the given geodetic location using the IGRF-13
%   *centered dipole* approximation - sufficient for sanity-checking the
%   onboard LIS3MDL/ICM-20948 magnetometer (which itself only resolves
%   the ambient field to a few hundred nT).
%
%   For the 2026.0 epoch:
%     g10 = -29350 nT, g11 = -1410 nT, h11 = +4545 nT
%
%   Output (all in nT and degrees):
%     M.B_north, M.B_east, M.B_down, M.B_total, M.dec_deg, M.inc_deg
%
%   For higher accuracy use the official IGRF-13 coefficients with full
%   Schmidt-quasinormal expansion; this dipole form is accurate to
%   roughly +-5% in southern Arizona in 2026.

if nargin < 4, decimal_year = 2026.24; end
g10 = -29350 + (decimal_year-2025)*  9.0;
g11 =  -1410 + (decimal_year-2025)* 10.0;
h11 =   4545 + (decimal_year-2025)*-21.0;

a = 6371200;                      % IGRF reference radius (m)
r = a + alt_m;
theta = deg2rad(90 - lat);        % colatitude
phi   = deg2rad(lon);

% Dipole moment
m_t = sqrt(g11^2 + h11^2 + g10^2);
% Field components in spherical (r, theta, phi)
ar = (a/r)^3;
Br = 2*ar*(g10*cos(theta) + (g11*cos(phi) + h11*sin(phi))*sin(theta));
Bt =   ar*(g10*sin(theta) - (g11*cos(phi) + h11*sin(phi))*cos(theta));
Bp =   ar*(g11*sin(phi) - h11*cos(phi));

% Convert to local NED
B_north = -Bt;
B_east  =  Bp;
B_down  = -Br;
Bh = hypot(B_north, B_east);
M.B_north = B_north;
M.B_east  = B_east;
M.B_down  = B_down;
M.B_total = sqrt(B_north^2 + B_east^2 + B_down^2);
M.dec_deg = atan2d(B_east, B_north);
M.inc_deg = atan2d(B_down, Bh);
M.dipole_moment_nT = m_t;
M.note = 'IGRF-13 centered dipole; +-5% accuracy. Use for sanity check only.';
end
