function W = ingest_windspeed(cfg)
%INGEST_WINDSPEED  Lateral wind-speed-vs-altitude (Vincenty-derived).
%
%   W = INGEST_WINDSPEED(cfg) returns a timetable with elapsed time,
%   altitude (m & ft), inter-fix great-circle distance (km), and
%   lateral / vertical / net speeds (mph) computed in the source workbook
%   via Vincenty's formula on the WGS-84 oblate spheroid.

raw = readcell(cfg.files.windspeed);
hdrRow = 18;          % MATLAB 1-based: row 18 is "time,latitude,..." header
data = raw(hdrRow+1:end, :);

n = size(data,1);
[t_s,lat,lon,alt_m,alt_ft,d_km,vlat_mph,vz_mph,vnet_mph] = deal(nan(n,1));
t_utc = NaT(n,1,'TimeZone','UTC');

for i = 1:n
    tv = data{i,1};
    if ischar(tv)||isstring(tv)
        try, t_utc(i) = datetime(tv,'InputFormat','yyyy-MM-dd HH:mm:ss','TimeZone','UTC'); catch, end
    elseif isa(tv,'datetime')
        t_utc(i)=tv; t_utc(i).TimeZone='UTC';
    end
    lat(i)      = num(data{i,2});
    lon(i)      = num(data{i,3});
    alt_m(i)    = num(data{i,4});
    alt_ft(i)   = num(data{i,5});
    t_s(i)      = num(data{i,10});
    d_km(i)     = num(data{i,19});
    vlat_mph(i) = num(data{i,21});
    vz_mph(i)   = num(data{i,22});
    vnet_mph(i) = num(data{i,23});
end

keep = ~isnat(t_utc) & ~isnan(alt_m);
t_utc=t_utc(keep); t_s=t_s(keep); lat=lat(keep); lon=lon(keep);
alt_m=alt_m(keep); alt_ft=alt_ft(keep); d_km=d_km(keep);
vlat_mph=vlat_mph(keep); vz_mph=vz_mph(keep); vnet_mph=vnet_mph(keep);

% Convert mph to m/s for downstream physics
mph2ms = 0.44704;
vlat_ms  = vlat_mph * mph2ms;
vz_ms    = vz_mph   * mph2ms;
vnet_ms  = vnet_mph * mph2ms;

W = timetable(t_utc, t_s, lat, lon, alt_m, alt_ft, d_km, ...
    vlat_mph, vz_mph, vnet_mph, vlat_ms, vz_ms, vnet_ms, ...
    'VariableNames', {'t_s','lat','lon','alt_m','alt_ft','d_km', ...
                      'vlat_mph','vz_mph','vnet_mph', ...
                      'vlat_ms','vz_ms','vnet_ms'});
W.Properties.DimensionNames{1}='time_utc';
W.Properties.UserData.max_vlat_mph = 39.8269;
W.Properties.UserData.max_vz_asc_mph = 24.7134;
W.Properties.UserData.max_vz_dsc_mph = -63.5635;
W.Properties.UserData.max_vnet_mph   = 63.6654;
end

function v = num(x)
if isnumeric(x), v = double(x);
elseif ischar(x)||isstring(x), v = str2double(x);
else, v = NaN; end
end
