function D = ingest_all(cfg)
%INGEST_ALL  Parse every raw ASCEND Spring 2026 dataset into a struct.
%
%   D = INGEST_ALL(cfg) returns:
%       D.trajectory  - APRS-derived trajectory (timetable)
%       D.wind        - Vincenty lateral wind speed (timetable)
%       D.geiger      - cosmic ray dose / CPM (timetable)
%       D.multi       - PM2.5 / CO2 / T / RH (timetable)
%       D.arduino     - UV / BMP390 / IMU / mag (timetable)
%
%   Cached as MAT in data/processed/ASCEND_S26_ingested.mat for speed.

cache = fullfile(cfg.paths.data_proc, 'ASCEND_S26_ingested.mat');
if isfile(cache) && nargout>0
    L = load(cache); D = L.D; return;
end

fprintf('[ASCEND-S26] Ingesting trajectory ... ');   D.trajectory = ingest_trajectory(cfg); fprintf('%d rows\n', height(D.trajectory));
fprintf('[ASCEND-S26] Ingesting windspeed  ... ');   D.wind       = ingest_windspeed(cfg);  fprintf('%d rows\n', height(D.wind));
fprintf('[ASCEND-S26] Ingesting geiger     ... ');   D.geiger     = ingest_geiger(cfg);     fprintf('%d rows\n', height(D.geiger));
fprintf('[ASCEND-S26] Ingesting multisensor... ');   D.multi      = ingest_multisensor(cfg);fprintf('%d rows\n', height(D.multi));
fprintf('[ASCEND-S26] Ingesting arduino    ... ');   D.arduino    = ingest_arduino(cfg);    fprintf('%d rows\n', height(D.arduino));

% website-derived public-release datasets (truth data)
fprintf('[ASCEND-S26] Ingesting website assets:\n');
try, D.web_payload   = ingest_website_payload(cfg);   catch ME, warning(ME.identifier,'%s',ME.message); D.web_payload   = timetable(); end
try, D.web_imu       = ingest_website_imu(cfg);       catch ME, warning(ME.identifier,'%s',ME.message); D.web_imu       = struct(); end
try, D.web_radiation = ingest_website_radiation(cfg); catch ME, warning(ME.identifier,'%s',ME.message); D.web_radiation = struct(); end
try, D.web_aprs      = ingest_website_aprs(cfg);      catch ME, warning(ME.identifier,'%s',ME.message); D.web_aprs      = struct(); end

save(cache, 'D');
fprintf('[ASCEND-S26] Cached -> %s\n', cache);
end
