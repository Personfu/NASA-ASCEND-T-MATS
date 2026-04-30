function viz_payload_sensors(PE, D, cfg)
%VIZ_PAYLOAD_SENSORS  Sensor suite spec sheet + measurement
%   uncertainty propagation for the Phoenix-1 payload (Personfu).
%
%   Renders the as-flown sensor inventory with ranges, accuracy, and
%   sample rates, then propagates uncertainties (RSS) onto derived
%   quantities (altitude from BMP390 pressure, density, dose-rate).
%
%   Output: figures/21_payload_sensors.{png,pdf}

% sensor catalog
S = {
  'BMP390 pressure',   '300-1250 hPa', '+/-3 Pa abs',  '50 Hz', 'I2C 0x77';
  'BMP390 temp',       '-40..85 C',    '+/-0.5 C',     '50 Hz', 'I2C 0x77';
  'SHT41 RH',          '0..100 %RH',   '+/-1.8 %RH',   '1 Hz',  'I2C 0x44';
  'SCD41 CO2',         '400..40000 ppm','+/-(40+5%) ppm','0.2 Hz','I2C 0x62';
  'PMS5003 PM1/2.5/10','0..1000 ug/m3','+/-(10+10%)',  '1 Hz',  'UART';
  'LSM6DSO accel',     '+/-16 g',      '<0.05 % FS',   '208 Hz','SPI';
  'LSM6DSO gyro',      '+/-2000 dps',  '<0.5 % FS',    '208 Hz','SPI';
  'LIS3MDL mag',       '+/-16 gauss',  '<3 mgauss',    '155 Hz','I2C';
  'GMC-320+ Geiger',   '0..1e6 CPM',   '+/-15 % typ',  '1 Hz',  'UART';
  'UV triad x4',       '0..14 UVI',    '+/-0.1 UVI',   '1 Hz',  'I2C 0x39';
  'GPS (LightAPRS)',   '<10 m CEP',    '<2.5 m typ',   '1 Hz',  'NMEA';
};
T = cell2table(S, 'VariableNames', ...
    {'sensor','range','accuracy','rate','interface'});

% altitude uncertainty from BMP390 vs altitude
h = linspace(0,26000,150);
[Ta, pa] = arrayfun(@local_atm, h);
sigma_p = 3;                       % Pa
dp_dh   = -gradient(pa, h);        % Pa/m
sigma_h = sigma_p ./ max(dp_dh, 1e-3);

% radiation rate uncertainty given Poisson + sensor 15%
cpm = logspace(1, 5, 100);
sigma_cpm_poisson = sqrt(cpm);
sigma_cpm_sensor  = 0.15 * cpm;
sigma_cpm_total   = sqrt(sigma_cpm_poisson.^2 + sigma_cpm_sensor.^2);

f = figure('Color','w','Position',[40 40 1620 980], ...
    'Name','Payload sensor suite (Personfu)');
tl = tiledlayout(f,2,2,'TileSpacing','compact','Padding','compact');

% sensor table view
ax = nexttile; axis(ax,'off');
uitable(f,'Data',T{:,:},'ColumnName',T.Properties.VariableNames, ...
    'Units','normalized','Position',ax.Position, ...
    'FontName','Consolas','FontSize',10);
title(ax,'Flown sensor suite','FontWeight','bold');

% altitude uncertainty
ax = nexttile; hold(ax,'on'); grid(ax,'on'); box(ax,'on');
plot(ax, sigma_h, h/1000, '-','Color',[0.10 0.45 0.85],'LineWidth',1.5);
xlabel(ax,'\sigma_h (m) from BMP390'); ylabel(ax,'altitude (km)');
title(ax,'Altitude uncertainty from \sigma_p = 3 Pa','FontWeight','bold');

% radiation uncertainty
ax = nexttile; hold(ax,'on'); grid(ax,'on'); box(ax,'on');
loglog(ax, cpm, sigma_cpm_total, '-','Color',[0.85 0.10 0.45],'LineWidth',1.5,'DisplayName','total');
loglog(ax, cpm, sigma_cpm_poisson,'--','Color',[0.4 0.4 0.4],'DisplayName','Poisson');
loglog(ax, cpm, sigma_cpm_sensor,':','Color',[0.95 0.55 0.10],'DisplayName','sensor 15%');
xlabel(ax,'CPM'); ylabel(ax,'\sigma (CPM)');
legend(ax,'Location','best');
title(ax,'GMC-320+ rate uncertainty','FontWeight','bold');

% live trace overlay if available
ax = nexttile; hold(ax,'on'); grid(ax,'on'); box(ax,'on');
if isfield(D,'arduino') && height(D.arduino)>10
    A = D.arduino;
    if any(strcmp(A.Properties.VariableNames,'press_pa'))
        ts = seconds(A.Time-A.Time(1));
        plot(ax, ts, A.press_pa/100,'-','Color',[0.10 0.30 0.85]);
        ylabel(ax,'P (hPa)');
    end
end
xlabel(ax,'time (s)');
title(ax,'BMP390 pressure trace','FontWeight','bold');

title(tl, sprintf('%s sensors  -  uncertainty propagation (Personfu)', PE.name), ...
    'FontWeight','bold','FontSize',13);

out = fullfile(cfg.paths.figures,'21_payload_sensors');
exportgraphics(f,[out '.png'],'Resolution',cfg.plot.dpi);
exportgraphics(f,[out '.pdf'],'ContentType','vector');
fprintf('  viz_payload_sensors    -> %s.{png,pdf}\n', out);
end

function [T,p] = local_atm(h)
g0=9.80665; R=287.05;
if h < 11000
    T = 288.15 - 0.0065*h; p = 101325*(T/288.15)^(g0/(R*0.0065));
elseif h < 20000
    T = 216.65; p = 22632.06*exp(-g0*(h-11000)/(R*T));
elseif h < 32000
    T = 216.65 + 0.001*(h-20000); p = 5474.89*(216.65/T)^(g0/(R*0.001));
else
    T = 228.65 + 0.0028*(h-32000); p = 868.02*(228.65/T)^(g0/(R*0.0028));
end
end
