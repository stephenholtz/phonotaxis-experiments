% Here we figure out what the peak particle velocity is for the pips
% without worrying about aligning anything to get a value for each stimulus
clearvars;

% Explicitly set path here
addpath(genpath('C:\code\phonotaxis-rig-experiments'))

% Top level data saving directory
data_dir = io.lookupDirectories('data');
stim_dir = io.lookupDirectories('stim');
calib_dir = io.lookupDirectories('calib');

amps_to_test = [0.1,0.4,0.7];

% Load in the acquired stimuli
load(fullfile(stim_dir,'pip_trains_01_speaker_4.mat'))
speaker_4_calib = all_stimuli;
load(fullfile(stim_dir,'pip_trains_01_speaker_4.mat'))
speaker_6_calib = all_stimuli;
delete all_stimuli

speakers_to_use = [4,6];
speaker_iter = 1;
for curr_speaker = speakers_to_use
    % We have calibration values for each speaker now
    if curr_speaker == 4
        curr_calib = speaker_4_calib;
    elseif curr_speaker == 6
        curr_calib = speaker_6_calib;
    else
        % lite error catching
        curr_calib = [];
    end
    
    [n_stimuli, n_amps, n_reps] = size(curr_calib);
    all_stim_lens = cellfun(@length,curr_calib);
    minlen = min(min(min(all_stim_lens)));
    
    mic_row = 2;
    kv_val = (3*10^-4);
    
    stim_mic_vals = [];
    for i_stim = 1:n_stimuli
        all_amps = [];
        for i_amp = 1:n_amps
            all_reps = [];
            for i_rep = 1:n_reps
                curr_pv = curr_calib{i_stim, i_amp, i_rep}(mic_row,1:minlen) * kv_val;
                all_reps = [all_reps; curr_pv];
            end
            all_amps = [all_amps; mean(max(abs(all_reps),[],2))];
        end
        stim_mic_vals = [stim_mic_vals, all_amps];
    end

    pv_mmps{speaker_iter} = 50 * 1000 * (kv_val * 100e3 ./ stim_mic_vals).^-1;
    speaker_iter = speaker_iter + 1;
end

%% Get mmps / volts factor per stmiulus
for i_speaker = 1:length(pv_mmps)
    % Go over all of the stimuli
    for i_stim = 1:size(pv_mmps{i_speaker},2)
        stim_pv_vals = pv_mmps{i_speaker}(:,i_stim);
        
        % fit a linear regression such that we get y=mx+b with x being the
        % particle velocity and y being the voltage required 
        mdl = fitlm(stim_pv_vals,amps_to_test', 'linear');
        b = mdl.Coefficients{1,1};
        m = mdl.Coefficients{2,1};

        calib(i_speaker).speaker_num = speakers_to_use(i_speaker);
        calib(i_speaker).m = m;
        calib(i_speaker).b = b;
    end
end

save(fullfile(calib_dir,'pip_trains_01.mat'))