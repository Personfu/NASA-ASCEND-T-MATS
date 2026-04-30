function M = ingest_multisensor(cfg)
%INGEST_MULTISENSOR  Plantower PM + SCD30 CO2/T/RH log.
%
%   M = INGEST_MULTISENSOR(cfg) returns a timetable with PM size bins
%   (mg/m3 - per spreadsheet header), CO2 (ppm), temperature (degC),
%   relative humidity (%), elapsed time, and altitude (ft) where present.

raw = readcell(cfg.files.multisensor);
% Row 1 blank, row 2 units, row 3 headers, row 4+ data
data = raw(4:end, :);
n = size(data,1);

t_utc = NaT(n,1,'TimeZone','UTC');
[pm03,pm05,pm10,pm25,pm50,pm100,co2,tempC,rh,t_s,alt_ft] = deal(nan(n,1));

for i = 1:n
    d = data{i,1};
    tt = data{i,2};
    if (ischar(d)||isstring(d)) && (ischar(tt)||isstring(tt))
        try
            % Multisensor logs in local MST (UTC-7), no DST in Arizona
            t_local = datetime(strtrim(string(d)+" "+string(tt)), ...
                'InputFormat','yyyy-MM-dd HH:mm:ss','TimeZone','America/Phoenix');
            t_utc(i) = t_local; t_utc(i).TimeZone = 'UTC';
        catch, end
    end
    pm25(i)  = num(data{i,3});
    pm10(i)  = num(data{i,4});  % per workbook header: PM1.0
    pm50(i)  = num(data{i,5});  % PM5.0
    pm05(i)  = num(data{i,6});  % PM0.5
    pm100(i) = num(data{i,7});  % PM10
    pm03(i)  = num(data{i,8});  % PM0.3
    co2(i)   = num(data{i,9});
    tempC(i) = num(data{i,10});
    rh(i)    = num(data{i,11});
    t_s(i)   = num(data{i,17});
    alt_ft(i)= num(data{i,19});
end

keep = ~isnat(t_utc);
t_utc=t_utc(keep);
pm03=pm03(keep); pm05=pm05(keep); pm10=pm10(keep); pm25=pm25(keep);
pm50=pm50(keep); pm100=pm100(keep);
co2=co2(keep); tempC=tempC(keep); rh=rh(keep);
t_s=t_s(keep); alt_ft=alt_ft(keep);

t_s_calc = seconds(t_utc - cfg.mission.launch_time_utc);
t_s(isnan(t_s)) = t_s_calc(isnan(t_s));

M = timetable(t_utc, t_s, alt_ft, pm03, pm05, pm10, pm25, pm50, pm100, ...
              co2, tempC, rh, ...
              'VariableNames', {'t_s','alt_ft','pm03','pm05','pm10','pm25','pm50','pm100','co2_ppm','temp_C','rh_pct'});
M.Properties.DimensionNames{1}='time_utc';
end

function v = num(x)
if isnumeric(x), v = double(x);
elseif ischar(x)||isstring(x), v = str2double(strtrim(string(x)));
else, v = NaN; end
end
