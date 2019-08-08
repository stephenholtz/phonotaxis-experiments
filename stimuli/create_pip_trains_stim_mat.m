% Create a structure called stim which contains the pip train, pip frequency, particle velocity
% and sample rate.
% Utilizes make_pip_train.m

%% Run a full experiment
% Prepare session
clearvars       % Clear variables
clc             % Clean command window
daq.reset()     % Restart daq
close all force % Close windows and interfaces

% Explicitly set path here
addpath(genpath('C:\code\phonotaxis-rig-experiments'))

% Top level data saving directory
data_dir = io.lookupDirectories('data');
stim_dir = io.lookupDirectories('stim');
calib_dir = io.lookupDirectories('calib');

% load in the calibration data
load(fullfile(calib_dir,'pip_trains_calib.mat'))

%%
n_total_speakers = 8;

pip_freqs = [225 400 575 750];
particle_vels = [0.5 0.75 1 1.5];
n_freqs = length(pip_freqs);
n_pvs = length(particle_vels);

%durations for stim
sine_duration = 0.03;
sample_rate = 192000;
dur_bn_pips_s = 0.03;
dur_bn_pips_samps = dur_bn_pips_s * sample_rate;
pre_gap_duration = 2;
post_gap_duration = 8;

stim = struct();
stim_num = 1;

do_plot = 0;
if do_plot
    figure();
end

% Once for the -45 and once for the +45
i_speaker = 1;
for curr_speaker = [4,6]
    for i = 1:n_freqs % cycle through stim frequencies
        for j = 1:n_pvs
            [train_stim, train_ts] = make_pip_train(pip_freqs(i),particle_vels(j),sample_rate);
            pre_gap = zeros(1,sample_rate*pre_gap_duration);
            post_gap = zeros(1,sample_rate*post_gap_duration);
            speaker_stim = [pre_gap train_stim post_gap];
            stim(stim_num).pv_stimulus = speaker_stim;
            
            calib_stim = calib(i_speaker).m * speaker_stim + calib(i_speaker).b;
            stim(stim_num).speaker_stimulus =  calib(i_speaker).m * speaker_stim + calib(i_speaker).b;
            
            if abs(calib_stim) > 0.99999
                error('Stimulus Amplitude is out of bounds for speaker!')
            end
            
            stim(stim_num).curr_speaker = curr_speaker;
            stim(stim_num).pip_freq = pip_freqs(i);
            stim(stim_num).particle_vels = particle_vels(j);
            stim(stim_num).sample_rate = sample_rate;
            if do_plot
                subplot(2,8,stim_num)
                plot(stim(stim_num).pip_train);
                title([pip_freqs(i) particle_vels(j)])
                ylim([-1.6,+1.6])
            end
            stim_num = stim_num + 1;
        end
    end
    i_speaker = i_speaker + 1;
end

stim_num = 1;
for i = 1:n_freqs % cycle through stim frequencies
    [train_stim, train_ts] = make_pip_train(pip_freqs(i),1,sample_rate);
    pre_gap = zeros(1,sample_rate*pre_gap_duration);
    post_gap = zeros(1,sample_rate*post_gap_duration);
    speaker_stim = [pre_gap train_stim post_gap];

    precalib_stim(stim_num).speaker_stimulus = speaker_stim;
    precalib_stim(stim_num).pip_freq = pip_freqs(i);
    precalib_stim(stim_num).sample_rate = sample_rate;
    
    stim_num = stim_num + 1;
end

save(fullfile(stim_dir,'pip_trains_01.mat'),'stim','precalib_stim');
