function [lat2,lon2,az2] = wgs84_destination(lat1,lon1,az1,d_m)
%WGS84_DESTINATION  Direct geodesic problem (Vincenty) on WGS-84.
%
%   [lat2,lon2,az2] = WGS84_DESTINATION(lat1,lon1,az1,d_m) computes the
%   destination (deg) given start lat/lon (deg), forward azimuth (deg
%   from north, clockwise), and geodesic distance d_m (meters).
%
%   Solves the *direct* problem of Vincenty (1975) on the WGS-84 ellipsoid
%   with iterative convergence to ~1e-12 rad.

a = 6378137.0; f = 1/298.257223563; b = a*(1-f);
phi1 = deg2rad(lat1); L1 = deg2rad(lon1); alpha1 = deg2rad(az1);
sinA1 = sin(alpha1); cosA1 = cos(alpha1);
tanU1 = (1-f)*tan(phi1); cosU1 = 1./sqrt(1+tanU1.^2); sinU1 = tanU1.*cosU1;

sigma1 = atan2(tanU1, cosA1);
sinAlpha = cosU1.*sinA1;
cos2Alpha = 1 - sinAlpha.^2;
u2 = cos2Alpha*(a^2 - b^2)/b^2;
A = 1 + u2/16384.*(4096+u2.*(-768+u2.*(320-175.*u2)));
B = u2/1024.*(256+u2.*(-128+u2.*(74-47.*u2)));

sigma = d_m./(b.*A);
sigmaP = 2*pi;
iter = 0;
while any(abs(sigma-sigmaP) > 1e-12) && iter < 100
    cos2sm = cos(2*sigma1 + sigma);
    sinSig = sin(sigma); cosSig = cos(sigma);
    dSigma = B.*sinSig.*(cos2sm + B/4.*(cosSig.*(-1+2*cos2sm.^2) - ...
             B/6.*cos2sm.*(-3+4*sinSig.^2).*(-3+4*cos2sm.^2)));
    sigmaP = sigma;
    sigma = d_m./(b.*A) + dSigma;
    iter = iter+1;
end

sinSig=sin(sigma); cosSig=cos(sigma);
tmp = sinU1.*sinSig - cosU1.*cosSig.*cosA1;
phi2 = atan2(sinU1.*cosSig + cosU1.*sinSig.*cosA1, ...
             (1-f).*sqrt(sinAlpha.^2 + tmp.^2));
lambda = atan2(sinSig.*sinA1, cosU1.*cosSig - sinU1.*sinSig.*cosA1);
C = f/16.*cos2Alpha.*(4 + f.*(4 - 3.*cos2Alpha));
L = lambda - (1-C).*f.*sinAlpha.*(sigma + C.*sinSig.*(cos2sm + C.*cosSig.*(-1+2.*cos2sm.^2)));
lon2 = rad2deg(L1 + L);
lat2 = rad2deg(phi2);
az2  = mod(rad2deg(atan2(sinAlpha, -tmp)), 360);
end
