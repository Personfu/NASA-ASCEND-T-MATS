function L = link_budget_aprs(cfg, traj)
%LINK_BUDGET_APRS  VHF APRS link budget vs altitude / range / elevation.
%
%   L = LINK_BUDGET_APRS(cfg, traj) computes free-space loss, atmospheric
%   absorption (ITU-R P.676 simplified), receiver SNR, and line-of-sight
%   horizon for the 144.39 MHz APRS link to a fixed ground station.
%
%   Channel model:
%     - Ptx     = 1 W (30 dBm) MicroTrak
%     - Gtx     = 0 dBi (1/4 wave whip, hemispherical pattern)
%     - Grx     = 6 dBi (typical fixed-station J-pole)
%     - Lcable  = 1.5 dB
%     - Lfade   = log-normal sigma 4 dB
%     - NF      = 3 dB, BW = 16 kHz, kT = -174 dBm/Hz
%   FSPL = 20 log10(d_km) + 20 log10(f_MHz) + 32.45  (d in km, f in MHz)
%   Atmospheric absorption above 5 km is negligible at 144 MHz; below 1 km
%   we add 0.005 dB/km*ground_range (rain margin = 0.2 dB).
%
%   Output: timetable with d_km, fspl_dB, atm_dB, prx_dBm, snr_dB,
%           elev_deg, los_horizon_km, link_margin_dB

f_MHz = 144.39;
Ptx_dBm = 30;
Gtx = 0; Grx = 6;
Lcable = 1.5;
NF = 3; BW = 16e3;
kTBW = -174 + 10*log10(BW) + NF;          % dBm
SNRmin = 10;                              % dB threshold for AFSK 1200 baud

% Ground station: Phoenix College ASCEND lab (rough coordinates)
gs.lat = 33.45; gs.lon = -112.075; gs.alt = 340;

n = height(traj);
[d_km, fspl, atm, prx, snr, elev, hzn, mar] = deal(zeros(n,1));
for i = 1:n
    [dh,~,~] = wgs84_inverse(gs.lat, gs.lon, traj.lat(i), traj.lon(i));
    dz = traj.alt_m(i) - gs.alt;
    d  = sqrt(dh^2 + dz^2);                       % slant range (m)
    d_km(i) = d/1000;
    fspl(i) = 20*log10(d_km(i)) + 20*log10(f_MHz) + 32.45;
    atm(i)  = 0.2 + 0.005*max(0,(1000-traj.alt_m(i)))/100;   % small
    prx(i)  = Ptx_dBm + Gtx + Grx - Lcable - fspl(i) - atm(i);
    snr(i)  = prx(i) - kTBW;
    elev(i) = atan2d(dz, dh);
    Re = 6371000; k4_3 = 4/3;
    hzn(i)  = sqrt(2*k4_3*Re*max(traj.alt_m(i)-gs.alt,1))/1000;  % km
    mar(i)  = snr(i) - SNRmin;
end

L = traj;
L.d_km        = d_km;
L.fspl_dB     = fspl;
L.atm_dB      = atm;
L.prx_dBm     = prx;
L.snr_dB      = snr;
L.elev_deg    = elev;
L.los_horizon_km = hzn;
L.link_margin_dB = mar;
L.Properties.UserData.gs = gs;
L.Properties.UserData.f_MHz = f_MHz;
L.Properties.UserData.SNRmin_dB = SNRmin;
L.Properties.UserData.kTBW_dBm  = kTBW;
end
