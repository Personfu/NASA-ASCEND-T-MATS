function A = ingest_arduino(cfg)
%INGEST_ARDUINO  UV (4-channel triad), BMP390, IMU, magnetometer log.
%
%   A = INGEST_ARDUINO(cfg) returns a timetable with synthesized
%   mean-of-channel UVA/UVB/UVC (mW/cm^2), pressure (Pa), barometric
%   altitude (m), 9-DOF IMU (gyro deg/s, accel m/s^2, mag uT) and the
%   workbook-derived elapsed seconds & altitude (ft).

raw = readcell(cfg.files.arduino);
data = raw(4:end, :);  % first 3 rows are merged headers / launch time
n = size(data,1);

[el_ms, uv1A,uv1B,uv1C, uv2A,uv2B,uv2C, uv3A,uv3B,uv3C, uv4A,uv4B,uv4C, ...
 press_Pa,temp_bmp,alt_bmp_m, gx,gy,gz, ax,ay,az, mx,my,mz, ...
 t_s,alt_ft,UVA_meanTorr,UVB_meanTorr,UVC_meanTorr,press_Torr,tempC, ...
 a_total_ms2,a_total_g] = deal(nan(n,1));

t_utc = NaT(n,1,'TimeZone','UTC');

for i = 1:n
    el_ms(i)  = num(data{i,2});
    uv1A(i)   = num(data{i,3});  uv1B(i)=num(data{i,4});   uv1C(i)=num(data{i,5});
    uv2A(i)   = num(data{i,6});  uv2B(i)=num(data{i,7});   uv2C(i)=num(data{i,8});
    uv3A(i)   = num(data{i,9});  uv3B(i)=num(data{i,10});  uv3C(i)=num(data{i,11});
    uv4A(i)   = num(data{i,12}); uv4B(i)=num(data{i,13});  uv4C(i)=num(data{i,14});
    press_Pa(i)= num(data{i,15});
    temp_bmp(i)= num(data{i,16});
    alt_bmp_m(i)= num(data{i,17});
    gx(i)=num(data{i,18}); gy(i)=num(data{i,19}); gz(i)=num(data{i,20});
    ax(i)=num(data{i,21}); ay(i)=num(data{i,22}); az(i)=num(data{i,23});
    mx(i)=num(data{i,24}); my(i)=num(data{i,25}); mz(i)=num(data{i,26});
    % Workbook-derived columns (start col 28+)
    h = num(data{i,28}); mn = num(data{i,29}); sc = num(data{i,30});
    if all(~isnan([h mn sc]))
        try
            t_utc(i) = cfg.mission.launch_time_utc;
            t_utc(i).Hour = h; t_utc(i).Minute = mn; t_utc(i).Second = sc;
        catch, end
    end
    t_s(i)         = num(data{i,32});
    alt_ft(i)      = num(data{i,33});
    UVA_meanTorr(i)= num(data{i,34});
    UVB_meanTorr(i)= num(data{i,35});
    UVC_meanTorr(i)= num(data{i,36});
    press_Torr(i)  = num(data{i,37});
    tempC(i)       = num(data{i,38});
    a_total_ms2(i) = num(data{i,39});
    a_total_g(i)   = num(data{i,40});
end

% UVA/B/C row means from raw 4-triad columns (mW/cm^2)
UVA = mean([uv1A uv2A uv3A uv4A], 2, 'omitnan');
UVB = mean([uv1B uv2B uv3B uv4B], 2, 'omitnan');
UVC = mean([uv1C uv2C uv3C uv4C], 2, 'omitnan');

% Fill timestamps
keep = ~isnan(el_ms);
fields = {el_ms,UVA,UVB,UVC,press_Pa,temp_bmp,alt_bmp_m, ...
          gx,gy,gz,ax,ay,az,mx,my,mz, t_s,alt_ft, a_total_ms2,a_total_g};
fnames = {'el_ms','UVA','UVB','UVC','press_Pa','temp_bmp','alt_bmp_m', ...
          'gx','gy','gz','ax','ay','az','mx','my','mz', ...
          't_s','alt_ft','a_total_ms2','a_total_g'};

t_utc = t_utc(keep);
S = struct();
for k = 1:numel(fields)
    S.(fnames{k}) = fields{k}(keep);
end

% Where t_utc is missing fall back to launch + el_ms
miss = isnat(t_utc);
t_utc(miss) = cfg.mission.launch_time_utc + seconds(S.el_ms(miss)/1000);

A = timetable(t_utc, S.t_s, S.alt_ft, S.UVA, S.UVB, S.UVC, ...
              S.press_Pa, S.temp_bmp, S.alt_bmp_m, ...
              S.gx, S.gy, S.gz, S.ax, S.ay, S.az, S.mx, S.my, S.mz, ...
              S.a_total_ms2, S.a_total_g, ...
              'VariableNames', {'t_s','alt_ft','UVA_mWcm2','UVB_mWcm2','UVC_mWcm2', ...
                                'press_Pa','temp_C','alt_baro_m', ...
                                'gyro_x_dps','gyro_y_dps','gyro_z_dps', ...
                                'accel_x_ms2','accel_y_ms2','accel_z_ms2', ...
                                'mag_x_uT','mag_y_uT','mag_z_uT', ...
                                'accel_total_ms2','accel_total_g'});
A.Properties.DimensionNames{1} = 'time_utc';
end

function v = num(x)
if isnumeric(x), v = double(x);
elseif ischar(x)||isstring(x), v = str2double(strtrim(string(x)));
else, v = NaN; end
end
