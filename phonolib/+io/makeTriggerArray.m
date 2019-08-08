function [trigger_array, n_triggers] = makeTriggerArray(frame_rate, duration_s, samp_rate, trig_dur_ms)
% Makes an array that can be used for camera triggering etc.,
% Input:
%   - frame_rate in hz
%   - duration_s
%   - samp_rate
%   - trig_dur_ms (optional)
% Output:
%   - trigger_array

    % Make a single trigger of all zeros and change a few samples to = 1
    trig = zeros(ceil((1/frame_rate) * samp_rate),1);
    
    if ~exist('trig_dur_ms','var')
        n_trig_samps = 100;
    else
        n_trig_samps = (trig_dur_ms/1000) * samp_rate;
    end
    
    trig(1:n_trig_samps) = 1;
    % Repeat the single trigger for the desired acquisition time 
    n_triggers = ceil(frame_rate*duration_s);
    trigger_array = repmat(trig, n_triggers, 1);