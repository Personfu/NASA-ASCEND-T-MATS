function PS = payload_systems()
%PAYLOAD_SYSTEMS  Phoenix College ASCEND Spring 2026 payload bill of materials,
%                 mass / CG / MOI properties, electrical interconnect, and
%                 sensor-by-sensor metadata.
%
%   PS = PAYLOAD_SYSTEMS() returns a hierarchical struct describing every
%   physical and logical subsystem of the Balloon-2 flight string.
%
%   The flight string from top to bottom is:
%
%        [BALLOON]  Kaymont 1500g latex (He filled, ~4.2 m^3 at launch)
%             |
%        [PARACHUTE]  Spherachute 36" (Cd~1.5)
%             |
%        [TRAIN LINE]  20 m, 1/8" nylon, with REFLECTOR
%             |
%        [PAYLOAD STACK]   <-- modeled here
%        +-------------------------+
%        | TRACKER MODULE          |  APRS Byonics MicroTrak
%        | MULTISENSOR MODULE      |  Plantower PMS5003 + SCD30
%        | ARDUINO MODULE          |  4x VEML6075 / SI1145, BMP390, ICM-20948, LIS3MDL
%        | GEIGER MODULE           |  GMC-320+
%        | POWER MODULE            |  8x Energizer L91 (2S4P)
%        +-------------------------+
%
%   All masses are flight-as-flown (g unless noted). MOI given about box CG
%   in body coordinates: x=fwd, y=stbd, z=down. Box outer dim 30x30x30 cm.

% =========================================================================
PS.box.outer_LWH_m   = [0.30, 0.30, 0.30];     % foamcore + duct tape
PS.box.wall_t_m      = 0.0254;                  % 1" foamcore
PS.box.material      = 'Polystyrene foamcore (rho=30 kg/m^3, k=0.033 W/mK)';
PS.box.surface       = 'External: white acrylic paint (alpha=0.78, eps=0.92)';
PS.box.fastener      = 'Duct tape + nylon zip ties (load-rated 22 kg)';
PS.box.color_hex     = '#FAFAFA';

% =========================================================================
% TRACKER MODULE  - APRS position / altitude beacon
% =========================================================================
PS.tracker = struct();
PS.tracker.name        = 'APRS-Tracker (KA7NSR-15)';
PS.tracker.vendor      = 'Byonics';
PS.tracker.model       = 'MicroTrak RTG (1 W)';
PS.tracker.callsign    = 'KA7NSR-15';
PS.tracker.beacon_int_s= 60;                    % nominal
PS.tracker.freq_MHz    = 144.390;               % 2 m amateur APRS NA
PS.tracker.power_W     = 1.0;                   % TX
PS.tracker.power_idle_W= 0.085;
PS.tracker.modulation  = 'Bell-202 AFSK 1200 baud, AX.25 UI';
PS.tracker.gps         = struct('chipset','u-blox MAX-M8Q','horiz_acc_m',2.5,'vert_acc_m',5.0, ...
                                'max_alt_m',50000,'max_v_ms',500);
PS.tracker.antenna     = 'Quarter-wave whip (1/4 lambda at 144.39 MHz = 0.519 m), VSWR<1.5';
PS.tracker.mass_g      = 180;
PS.tracker.cg_mm       = [0,0,-90];             % below box midplane
PS.tracker.moi_kgm2    = diag([5.4e-4, 5.4e-4, 1.1e-4]);
PS.tracker.connector   = 'JST-PH 2-pin (5V), SMA RF';

% =========================================================================
% MULTISENSOR MODULE - PM, CO2, T, RH
% =========================================================================
PS.multi = struct();
PS.multi.name          = 'Multisensor (atmospheric chemistry)';
PS.multi.host          = 'Arduino MEGA 2560 (separate from "arduino" stack)';
PS.multi.sensors(1) = struct('part','PMS5003','vendor','Plantower', ...
    'measurand','PM 0.3/0.5/1.0/2.5/5.0/10 um', ...
    'unit','ug/m^3','range','0-1000','i2c_addr','UART','sample_Hz',1, ...
    'note','Internal fan; performance degrades below ~50 mbar');
PS.multi.sensors(2) = struct('part','SCD30','vendor','Sensirion', ...
    'measurand','CO2 / T / RH','unit','ppm / degC / %', ...
    'range','400-10000 / -40-70 / 0-100','i2c_addr','0x61','sample_Hz',0.5, ...
    'note','NDIR + SHT31; internal pressure compensation');
PS.multi.power_W       = 0.95;                  % fan dominant
PS.multi.mass_g        = 420;
PS.multi.cg_mm         = [50, 0, -20];
PS.multi.moi_kgm2      = diag([1.3e-3, 1.3e-3, 6.5e-4]);
PS.multi.log_rate_Hz   = 0.2;                   % 5 s sample storage

% =========================================================================
% ARDUINO MODULE - UV / pressure / IMU / mag
% =========================================================================
PS.arduino = struct();
PS.arduino.name        = 'Science Stack (Arduino UNO R4 WiFi)';
PS.arduino.mcu         = 'Renesas RA4M1 (48 MHz Cortex-M4)';
PS.arduino.clock_MHz   = 48;
PS.arduino.flash_kB    = 256;
PS.arduino.sram_kB     = 32;
PS.arduino.power_W     = 0.55;
PS.arduino.log_rate_Hz = 2.0;                   % every 500 ms
PS.arduino.storage     = 'microSD via SPI (32 GB SDHC, FAT32)';
PS.arduino.sensors(1)  = struct('part','VEML6075/SI1145 quad','count',4, ...
    'channels','UVA(365nm) UVB(300nm) UVC(260nm) per chip', ...
    'unit','mW/cm^2','range','0-50', ...
    'i2c_addr','0x10/0x60','note','4-position triad gives spatial average over box face');
PS.arduino.sensors(2)  = struct('part','BMP390','vendor','Bosch', ...
    'measurand','pressure / temp','unit','Pa / degC','range','3000-125000 / -40-85', ...
    'i2c_addr','0x77','sample_Hz',50,'note','High-precision baro alt (sigma~0.5 m)');
PS.arduino.sensors(3)  = struct('part','ICM-20948','vendor','TDK Invensense', ...
    'measurand','9-axis IMU (gyro+accel+mag)','unit','dps / m/s^2 / uT', ...
    'range','+-2000 dps / +-16 g / +-4900 uT','i2c_addr','0x68','sample_Hz',100, ...
    'note','Gyro ARW 0.005 dps/sqrt(Hz), accel noise 230 ug/sqrt(Hz)');
PS.arduino.sensors(4)  = struct('part','LIS3MDL','vendor','ST', ...
    'measurand','3-axis magnetometer','unit','uT','range','+-1600 uT', ...
    'i2c_addr','0x1C','sample_Hz',80,'note','Backup mag, 4 mGauss noise');
PS.arduino.mass_g      = 540;
PS.arduino.cg_mm       = [-30, 0, 30];
PS.arduino.moi_kgm2    = diag([1.6e-3, 1.6e-3, 8.0e-4]);

% =========================================================================
% GEIGER MODULE
% =========================================================================
PS.geiger = struct();
PS.geiger.name         = 'Cosmic-ray detector';
PS.geiger.vendor       = 'GQ Electronics';
PS.geiger.model        = 'GMC-320 Plus';
PS.geiger.tube         = 'M4011 (compensated GM, 22 mm x 110 mm)';
PS.geiger.energy_range = '50 keV - 3 MeV (gamma); ~200 keV beta';
PS.geiger.cps_per_uSvph= 0.1525*60/100;        % ~91 CPM per uSv/h
PS.geiger.bg_uSvph     = 0.10;
PS.geiger.power_W      = 0.20;
PS.geiger.battery_int  = '3.7 V Li-Po (internal 1000 mAh, NOT used in flight)';
PS.geiger.log_mode     = 'Every Second  (1 Hz, EEPROM 1 MB)';
PS.geiger.mass_g       = 260;
PS.geiger.cg_mm        = [0, 50, 0];
PS.geiger.moi_kgm2     = diag([5.0e-4, 2.5e-4, 5.0e-4]);

% =========================================================================
% POWER MODULE - lithium primary
% =========================================================================
PS.power = struct();
PS.power.cell.part     = 'Energizer L91 Ultimate Lithium AA';
PS.power.cell.chem     = 'Li-FeS2 primary';
PS.power.cell.V_nom    = 1.5;
PS.power.cell.V_oc     = 1.78;
PS.power.cell.V_eod    = 0.90;                  % end-of-discharge
PS.power.cell.cap_Ah   = 3.50;                  % @ 25 mA, -20 C derate ~20%
PS.power.cell.mass_g   = 14.5;
PS.power.cell.T_op_C   = [-40, 60];
PS.power.pack.config   = '2S4P (2 in series x 4 in parallel)';
PS.power.pack.V_nom    = 6.0;
PS.power.pack.cap_Ah   = 14.0;
PS.power.pack.energy_Wh= 84.0;
PS.power.regulator     = 'TI TPS63070 buck-boost (3.3V/5V rails, 95% eta)';
PS.power.protection    = 'Polyfuse 3 A + reverse-polarity diode + per-rail TVS';
PS.power.heater        = 'Resistive Kapton heater 6 V / 1.2 W on multisensor mainboard';
PS.power.heater_setpt_C= -10;
PS.power.mass_g        = 240;
PS.power.cg_mm         = [0, 0, 50];
PS.power.moi_kgm2      = diag([1.0e-3, 1.0e-3, 4.0e-4]);

% =========================================================================
% PARACHUTE / TRAIN LINE / REFLECTOR
% =========================================================================
PS.parachute.model     = 'Spherachute 36" (custom hemispherical canopy)';
PS.parachute.diameter_m= 0.9144;
PS.parachute.cd        = 1.50;
PS.parachute.area_m2   = pi*(0.9144/2)^2;
PS.parachute.mass_g    = 60;
PS.parachute.shroud_lines = 8;
PS.parachute.ko_factor    = 1.0;                % "always-open" at burst (no reefing)

PS.train.length_m      = 20.0;
PS.train.material      = '1/8" braided nylon (rated 90 kg)';
PS.train.mass_g        = 25;
PS.train.reflector     = 'Aluminized mylar radar reflector (octahedral, 30 cm)';

% =========================================================================
% AGGREGATE MASS / CG / MOI
% =========================================================================
modules = {'tracker','multi','arduino','geiger','power'};
PS.totals.dry_mass_g = 0;  rs = zeros(numel(modules),3); ms = zeros(numel(modules),1); Js = zeros(3);
for k = 1:numel(modules)
    m  = PS.(modules{k});
    PS.totals.dry_mass_g = PS.totals.dry_mass_g + m.mass_g;
    rs(k,:) = m.cg_mm/1000;
    ms(k)   = m.mass_g/1000;
end
PS.totals.cg_m  = sum(rs.*ms,1)/sum(ms);

% Parallel-axis transfer of MOI to overall CG
for k = 1:numel(modules)
    m   = PS.(modules{k});
    mk  = m.mass_g/1000;
    rk  = m.cg_mm/1000 - PS.totals.cg_m;
    Jk  = m.moi_kgm2 + mk*( (rk*rk')*eye(3) - (rk'*rk) );
    Js  = Js + Jk;
end
PS.totals.moi_kgm2 = Js;
PS.totals.flight_mass_g = PS.totals.dry_mass_g + PS.parachute.mass_g + PS.train.mass_g;

% =========================================================================
% I2C / UART BUS MAP
% =========================================================================
PS.bus.i2c0 = {'BMP390 0x77','ICM-20948 0x68','LIS3MDL 0x1C','SCD30 0x61','VEML6075 0x10'};
PS.bus.uart0= {'PMS5003 (9600 8N1)'};
PS.bus.spi0 = {'microSD CS=10'};
PS.bus.gpio = struct('heater_pwm','D5','status_led','D13','sd_cs','D10');

% =========================================================================
% FAA PART 101 COMPLIANCE  (unmanned free balloon)
% =========================================================================
PS.faa.payload_class   = 'Light (single payload < 4 lb / 1.81 kg AND < 2 lb/in^2 / 13.8 kPa areal density)';
PS.faa.areal_density   = (PS.totals.flight_mass_g/1000) * 9.80665 / ...
                         (PS.box.outer_LWH_m(1)*PS.box.outer_LWH_m(2));     % Pa = N/m^2
PS.faa.areal_density_psi = PS.faa.areal_density / 6894.76;
PS.faa.compliant       = (PS.totals.flight_mass_g < 1814) && (PS.faa.areal_density_psi < 2.0);
PS.faa.notam_required  = false;                  % Light class
PS.faa.section         = 'Part 101 Subpart D (Moored / Unmanned Free Balloons)';

% =========================================================================
PS.notes = {
 '* All sensors logged on independent storage; no single-point data loss.';
 '* Geiger/multisensor stamp time in local Arizona MST (UTC-7); APRS in UTC.';
 '* Heater is thermostatic with 2 K hysteresis (ON below -11 C, OFF above -9 C).';
 '* FAA Part 101 LIGHT class -> no NOTAM, but 24h notice was filed via FSS.';
 '* Data integrity verified by cross-checking BMP390 alt vs APRS GPS alt.';
};
end
