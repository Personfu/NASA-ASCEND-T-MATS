function R = simulate_power(cfg, thermal)
%SIMULATE_POWER  Coulomb-counted battery + thermostatic heater duty.
%
%   R = SIMULATE_POWER(cfg, thermal) returns timetable with bus power
%   (W), instantaneous current (A), accumulated energy (Wh), depth-of-
%   discharge (%), and remaining capacity (Wh).

p   = cfg.power;
loads = struct2array(p.loads);  % vector of W
P_const = sum(structfun(@(x)x,p.loads)) - p.loads.heater_W;
heater = thermal.heater_on;

n = height(thermal);
t = seconds(thermal.t);
P = P_const + heater*p.loads.heater_W;
I = P / p.pack_voltage_V;

E_used = zeros(n,1);
for i = 2:n
    dt_h = (t(i)-t(i-1))/3600;
    E_used(i) = E_used(i-1) + P(i)*dt_h;
end
DoD  = 100*E_used/p.pack_energy_Wh;
E_rem= p.pack_energy_Wh - E_used;

R = timetable(thermal.t, thermal.alt_m, P, I, E_used, DoD, E_rem, ...
    'VariableNames',{'alt_m','bus_power_W','bus_current_A','energy_used_Wh','DoD_pct','energy_remaining_Wh'});
R.Properties.DimensionNames{1}='t';
end
