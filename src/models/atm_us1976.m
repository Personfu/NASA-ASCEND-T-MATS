function [T,P,rho,a,mu,nu] = atm_us1976(h_m)
%ATM_US1976  U.S. Standard Atmosphere 1976.
%
%   [T,P,rho,a,mu,nu] = ATM_US1976(h_m) returns temperature [K], pressure
%   [Pa], density [kg/m^3], speed of sound [m/s], dynamic viscosity
%   [Pa s] and kinematic viscosity [m^2/s] for geometric altitude h_m.
%
%   Valid 0 - 86 km.  Above 86 km values are extrapolated using the
%   uppermost layer (good enough for high-altitude balloon flight which
%   tops out around ~36 km even for zero-pressure balloons).
%
%   Reference: NOAA/NASA/USAF, "U.S. Standard Atmosphere, 1976",
%              NASA-TM-X-74335, Tables I-IV; ISA piecewise barometric.

if isempty(h_m), T=[];P=[];rho=[];a=[];mu=[];nu=[]; return; end
h_m = h_m(:);

% --- constants ----------------------------------------------------------
g0 = 9.80665;             % m/s^2
R  = 287.05287;           % J/(kg K) - dry air
gamma = 1.4;
Re = 6356766;             % m  effective Earth radius
S  = 110.4;               % K  Sutherland
beta = 1.458e-6;          % kg/(m s K^0.5)

% --- US-1976 layer breakpoints (geopotential alt H, base T, lapse) -----
%  H base [m gp] | Tb [K]    | Lb [K/m]
L = [    0,       288.15,    -0.0065;     % troposphere
     11000,       216.65,     0.0;        % tropopause
     20000,       216.65,     0.001;      % stratosphere 1
     32000,       228.65,     0.0028;     % stratosphere 2
     47000,       270.65,     0.0;        % stratopause
     51000,       270.65,    -0.0028;     % mesosphere 1
     71000,       214.65,    -0.002;      % mesosphere 2
     84852,       186.946,    0.0];

% Pressure at base of each layer (Pa) - sea level reference
Pb = zeros(size(L,1),1);
Pb(1) = 101325;
for k = 2:size(L,1)
    Tb = L(k-1,2); Lb = L(k-1,3); Hb = L(k-1,1); Hk = L(k,1);
    if Lb == 0
        Pb(k) = Pb(k-1)*exp(-g0*(Hk-Hb)/(R*Tb));
    else
        Pb(k) = Pb(k-1)*(Tb/(Tb+Lb*(Hk-Hb)))^(g0/(R*Lb));
    end
end

% Geometric -> geopotential altitude
H = Re.*h_m ./ (Re + h_m);

T = zeros(size(H));
P = zeros(size(H));
for i = 1:numel(H)
    Hi = H(i);
    k  = find(L(:,1) <= Hi, 1, 'last');
    if isempty(k), k = 1; end
    if k == size(L,1)
        Tb = L(k,2); Lb = 0; Hb = L(k,1); Pbk = Pb(k);
    else
        Tb = L(k,2); Lb = L(k,3); Hb = L(k,1); Pbk = Pb(k);
    end
    Ti = Tb + Lb*(Hi-Hb);
    if Lb == 0
        Pi = Pbk*exp(-g0*(Hi-Hb)/(R*Tb));
    else
        Pi = Pbk*(Tb/Ti)^(g0/(R*Lb));
    end
    T(i) = Ti; P(i) = Pi;
end

rho = P ./ (R*T);
a   = sqrt(gamma*R*T);
mu  = beta .* T.^1.5 ./ (T + S);     % Sutherland
nu  = mu ./ rho;
end
