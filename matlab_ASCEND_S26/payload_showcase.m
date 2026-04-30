function results = payload_showcase(varargin)
%PAYLOAD_SHOWCASE  Master "show off the payload" runner for NASA ASCEND.
%
%   RESULTS = PAYLOAD_SHOWCASE() runs every Fundamental and Advanced
%   payload-side analysis, simulation, and visualization that has been
%   built for the Phoenix College Spring 2026 carbon-fiber 3 lb payload:
%
%     1. Decode firmware CSV (or simulate one if the file is missing)
%     2. Health summary + sensor uptime
%     3. CAD payload render
%     4. Structural / thermal / aero / power / link / sensor dashboards
%     5. Firmware telemetry replay
%     6. 6-DOF dynamics (tilt, omega, energy, complementary attitude)
%     7. FFT / PSD vibration analysis
%     8. Kalman altitude fusion (BMP + a_z)
%     9. Allan-variance gyro characterisation
%    10. Beer-Lambert UV vs altitude fit
%    11. Monte Carlo recovery dispersion
%    12. BOM + engineering markdown export
%    13. UBX airborne packet generation + EEPROM round-trip self test
%
%   The function never errors out on a single missing piece; each step
%   is wrapped so the rest of the showcase still runs and gets exported.
%
%   Phoenix College NASA ASCEND Spring 2026 - HailMaryV1f.

p = inputParser;
p.addParameter('csv', '', @(s) ischar(s) || isstring(s));
p.addParameter('figdir', fullfile(pwd, 'figures'), @(s) ischar(s) || isstring(s));
p.addParameter('reportdir', fullfile(pwd, 'reports'), @(s) ischar(s) || isstring(s));
p.parse(varargin{:});
opt = p.Results;

repoRoot = fileparts(mfilename('fullpath'));
addpath(genpath(repoRoot));

if ~isfolder(opt.figdir),    mkdir(opt.figdir);    end
if ~isfolder(opt.reportdir), mkdir(opt.reportdir); end

cfg = struct('figdir', char(opt.figdir));

results = struct();
fprintf('\n=========================================================\n');
fprintf(' PHOENIX COLLEGE NASA ASCEND - PAYLOAD SHOWCASE\n');
fprintf(' Phoenix-1 carbon-fiber 3 lb internal-sensor payload\n');
fprintf(' Firmware: HailMaryV1f  (Spring 2026 flight)\n');
fprintf('=========================================================\n\n');

% --- 1. Decode CSV or simulate ---
T = [];
csv = char(opt.csv);
if ~isempty(csv) && isfile(csv)
    fprintf('[01] Decoding firmware CSV: %s\n', csv);
    try
        T = firmware_decode_csv(csv);
        fprintf('     -> %d rows decoded.\n', height(T));
    catch ME
        warning('firmware_decode_csv failed: %s', ME.message);
    end
end
if isempty(T)
    fprintf('[01] No CSV provided -> running firmware-in-the-loop simulator.\n');
    T = firmware_simulate_flight(struct(), struct('seed',2026));
    fprintf('     -> %d simulated rows generated.\n', height(T));
end
results.telemetry = T;

% --- 2. Health summary ---
local_run('[02] Health summary',  @() firmware_health_summary(T), 'health');

% --- 3..9 Visual dashboards (each guarded) ---
local_run('[03] CAD payload render',          @() viz_payload_cad(cfg),                  'cad');
local_run('[04] Structural margins',          @() viz_payload_structural(cfg),           'structural');
local_run('[05] Thermal skin/core model',     @() viz_payload_thermal_skin(cfg),         'thermal');
local_run('[06] Aerodynamics dashboard',      @() viz_payload_aero(cfg),                 'aero');
local_run('[07] Power bus dashboard',         @() viz_payload_power(cfg),                'power');
local_run('[08] APRS link budget',            @() viz_payload_link_budget(cfg),          'link');
local_run('[09] Sensor suite + uncertainty',  @() viz_payload_sensors(cfg),              'sensors');

% --- 10..14 Telemetry-driven advanced suite ---
local_run('[10] Firmware telemetry replay',   @() viz_firmware_replay(T, cfg),           'replay');
local_run('[11] 6-DOF dynamics',              @() viz_payload_dynamics(T, cfg),          'dynamics');
local_run('[12] Vibration / PSD',             @() viz_payload_vibration(T, cfg),         'vibration');
local_run('[13] Kalman altitude fusion',      @() viz_payload_kalman(T, cfg),            'kalman');
local_run('[14] Allan-variance gyro',         @() viz_payload_allan(T, cfg),             'allan');
local_run('[15] UV vs altitude fit',          @() viz_payload_uv_atmo(T, cfg),           'uv_atmo');

% --- 16. Monte Carlo recovery ---
local_run('[16] Monte Carlo dispersion', ...
    @() viz_payload_montecarlo(struct('figdir',cfg.figdir,'nTrials',500)), ...
    'montecarlo');

% --- 17. BOM + engineering markdown ---
local_run('[17] BOM + engineering markdown', ...
    @() export_payload_bom(struct('reportdir',char(opt.reportdir))), 'bom');

% --- 18. Firmware self-tests ---
fprintf('[18] Firmware self-tests:\n');
try
    [pkt, ckA, ckB] = firmware_ubx_airborne();
    fprintf('     UBX airborne packet: %d bytes, ckA=0x%02X ckB=0x%02X\n', ...
        numel(pkt), ckA, ckB);
    results.ubx = struct('packet', pkt, 'ckA', ckA, 'ckB', ckB);

    bytes = firmware_eeprom_pack(32.87533, -112.0495, 482.0);
    [lat, lng, alt] = firmware_eeprom_unpack(bytes);
    fprintf('     EEPROM round-trip: lat=%.6f lng=%.6f alt=%.2f m\n', lat, lng, alt);
    results.eeprom = struct('packed', bytes, 'lat', lat, 'lng', lng, 'alt', alt);
catch ME
    warning('Firmware self-test failed: %s', ME.message);
end

fprintf('\nShowcase complete. Figures: %s\n', opt.figdir);
fprintf('Reports: %s\n', opt.reportdir);

    function local_run(label, fn, key)
        fprintf('%s\n', label);
        try
            out = fn();
            if nargin >= 3
                results.(key) = out;
            end
        catch ME
            warning('%s failed: %s', label, ME.message);
        end
    end
end
