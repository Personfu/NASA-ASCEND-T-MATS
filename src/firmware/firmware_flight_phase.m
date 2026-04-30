function [phase, state] = firmware_flight_phase(altSeries, fresh, state)
%FIRMWARE_FLIGHT_PHASE  Replicate the HailMaryV1f flight-phase state machine.
%
%   [PHASE, STATE] = FIRMWARE_FLIGHT_PHASE(ALTSERIES) runs the V1f
%   altitude-driven state machine on a vector ALTSERIES and returns a
%   PHASE vector of the same length plus the final STATE struct. The
%   thresholds and counter behaviour are identical to the AVR firmware:
%
%     GROUND  -> ASCENT  : alt > launch + 100 m
%     ASCENT  -> FLOAT   : 5 consecutive samples with |d_alt| < 2 m
%     FLOAT   -> DESCENT : peak - alt > 50 m
%     DESCENT -> LANDED  : alt - launch < 200 m AND |d_alt| < 1 m
%     LANDED  : terminal (also reachable via impact >15 g)
%
%   FIRMWARE_FLIGHT_PHASE(ALTSERIES, FRESH) accepts a logical FRESH
%   vector marking which samples come from a fresh BMP read; stale
%   samples are passed through with the previous phase, matching the
%   firmware's `if (!launchAltitudeSet || !altFresh) return flightPhase;`.
%
%   FIRMWARE_FLIGHT_PHASE(ALTSERIES, FRESH, STATE) lets you stream the
%   state machine across multiple chunks (e.g., live serial replay).
%
%   Constants:
%     ASCENT_TRIGGER_M = 100 m
%     FLOAT_RATE_MS    = 2 m / sample
%     DESCENT_DROP_M   = 50 m
%     LANDED_ALT_M     = 200 m
%     LANDED_RATE_MS   = 1 m / sample

if nargin < 2 || isempty(fresh), fresh = true(size(altSeries)); end
if nargin < 3 || isempty(state)
    state = struct('phase', 0, 'launch', NaN, 'peak', -Inf, ...
                   'prev', NaN, 'floatCounter', 0);
end

altSeries = double(altSeries(:));
fresh     = logical(fresh(:));
N = numel(altSeries);
phase = zeros(N, 1, 'uint8');

ASCENT_TRIGGER_M = 100;
FLOAT_RATE_MS    = 2;
DESCENT_DROP_M   = 50;
LANDED_ALT_M     = 200;
LANDED_RATE_MS   = 1;

for i = 1:N
    a = altSeries(i);
    f = fresh(i);

    if isnan(state.launch) && f && ~isnan(a)
        state.launch = a;
        state.peak   = a;
        state.prev   = a;
    end

    if ~f || isnan(state.launch)
        phase(i) = state.phase;
        continue
    end

    if a > state.peak
        state.peak = a;
    end
    aboveLaunch  = a - state.launch;
    verticalDelta = a - state.prev;
    state.prev = a;

    switch state.phase
        case 0  % GROUND
            if aboveLaunch > ASCENT_TRIGGER_M
                state.phase = 1;
                state.floatCounter = 0;
            end
        case 1  % ASCENT
            if abs(verticalDelta) < FLOAT_RATE_MS
                state.floatCounter = state.floatCounter + 1;
                if state.floatCounter >= 5
                    state.phase = 2;
                end
            else
                state.floatCounter = 0;
            end
        case 2  % FLOAT
            if state.peak - a > DESCENT_DROP_M
                state.phase = 3;
            end
        case 3  % DESCENT
            if aboveLaunch < LANDED_ALT_M && abs(verticalDelta) < LANDED_RATE_MS
                state.phase = 4;
            end
        case 4  % LANDED
            % terminal
    end

    phase(i) = state.phase;
end
end
