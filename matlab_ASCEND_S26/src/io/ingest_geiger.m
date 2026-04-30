function G = ingest_geiger(cfg)
%INGEST_GEIGER  Parse GMC-320 Geiger counter log (uSv/h, CPM).
%
%   G = INGEST_GEIGER(cfg) returns a timetable: dose_uSvph, cpm, sample_type.

raw = readcell(cfg.files.geiger);
% header at row 2: Date Time, Type, uSv/h, CPM
data = raw(3:end, 1:4);
n = size(data,1);

t_utc = NaT(n,1,'TimeZone','UTC');
[dose, cpm] = deal(nan(n,1));
sample = strings(n,1);

for i = 1:n
    tv = data{i,1};
    if ischar(tv)||isstring(tv)
        try
            % GMC-320 logs in local MST (UTC-7), no DST in Arizona
            t_local = datetime(tv,'InputFormat','yyyy-MM-dd HH:mm:ss','TimeZone','America/Phoenix');
            t_utc(i) = t_local; t_utc(i).TimeZone = 'UTC';
        catch, end
    elseif isa(tv,'datetime')
        t_utc(i)=tv; t_utc(i).TimeZone='UTC';
    end
    sample(i) = string(data{i,2});
    dose(i)   = num(data{i,3});
    cpm(i)    = num(data{i,4});
end

keep = ~isnat(t_utc);
t_utc=t_utc(keep); sample=sample(keep); dose=dose(keep); cpm=cpm(keep);

% Elapsed seconds since launch
t_s = seconds(t_utc - cfg.mission.launch_time_utc);

G = timetable(t_utc, t_s, dose, cpm, categorical(sample), ...
    'VariableNames', {'t_s','dose_uSvph','cpm','sample_type'});
G.Properties.DimensionNames{1} = 'time_utc';
end

function v = num(x)
if isnumeric(x), v = double(x);
elseif ischar(x)||isstring(x), v = str2double(x);
else, v = NaN; end
end
