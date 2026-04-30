function [d_m,az_fwd,az_rev] = wgs84_inverse(lat1,lon1,lat2,lon2)
%WGS84_INVERSE  Vincenty's inverse geodesic on WGS-84.
%
%   [d_m,az_fwd,az_rev] = WGS84_INVERSE(lat1,lon1,lat2,lon2)
%   distance (m), forward & reverse azimuth (deg).

a=6378137.0; f=1/298.257223563; b=a*(1-f);
U1 = atan((1-f).*tan(deg2rad(lat1)));
U2 = atan((1-f).*tan(deg2rad(lat2)));
L  = deg2rad(lon2 - lon1);
sinU1=sin(U1); cosU1=cos(U1); sinU2=sin(U2); cosU2=cos(U2);

lambda = L; lambdaP = 2*pi; iter=0;
while any(abs(lambda-lambdaP) > 1e-12) && iter < 100
    sinL=sin(lambda); cosL=cos(lambda);
    sinSig = sqrt((cosU2.*sinL).^2 + (cosU1.*sinU2 - sinU1.*cosU2.*cosL).^2);
    cosSig = sinU1.*sinU2 + cosU1.*cosU2.*cosL;
    sigma  = atan2(sinSig,cosSig);
    sinAlpha = cosU1.*cosU2.*sinL./sinSig;
    cos2Alpha = 1 - sinAlpha.^2;
    cos2sm = cosSig - 2.*sinU1.*sinU2./cos2Alpha;
    cos2sm(~isfinite(cos2sm)) = 0;
    C = f/16.*cos2Alpha.*(4 + f.*(4 - 3.*cos2Alpha));
    lambdaP = lambda;
    lambda = L + (1-C).*f.*sinAlpha.* ...
        (sigma + C.*sinSig.*(cos2sm + C.*cosSig.*(-1+2.*cos2sm.^2)));
    iter=iter+1;
end
u2 = cos2Alpha.*(a^2-b^2)/b^2;
A = 1 + u2/16384.*(4096+u2.*(-768+u2.*(320-175.*u2)));
B = u2/1024.*(256+u2.*(-128+u2.*(74-47.*u2)));
dSigma = B.*sinSig.*(cos2sm + B/4.*(cosSig.*(-1+2.*cos2sm.^2) - ...
         B/6.*cos2sm.*(-3+4.*sinSig.^2).*(-3+4.*cos2sm.^2)));
d_m = b.*A.*(sigma - dSigma);
az_fwd = mod(rad2deg(atan2(cosU2.*sin(lambda), cosU1.*sinU2 - sinU1.*cosU2.*cos(lambda))),360);
az_rev = mod(rad2deg(atan2(cosU1.*sin(lambda), -sinU1.*cosU2 + cosU1.*sinU2.*cos(lambda))),360);
end
