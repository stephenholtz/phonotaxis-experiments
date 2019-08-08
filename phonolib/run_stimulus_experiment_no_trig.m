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

%% Input parameters and metadata, load stimulus, and make directories
% fly's genotype for this experiment
fly_genotype = 'CS';
fly_dob = '';

% Select which stimulus and calibration struct to load and deliver, relies on calibration file sharing a name 
stim_type = 1;
switch stim_type
    case 1
        stim_name = 'pip_trains_01';
    otherwise
        error('Stimulus type not specified')
end
load(fullfile(stim_dir,stim_name));

% Number of speakers to use, should be 8 unless we modify things
n_speakers = 8;

% speaker setting, the knob on the front for all channels
speaker_amp_value_db = 0;

% Seraph 8+ mixer settings
daw_out_amp = '+0db';

% Camera frame rate in hz
frame_rate = 85;

% Specific top level experimental file saving folder
ds = datestr(now,30);
recording_folder = [ds '_' stim_name '_' fly_genotype];
save_dir_top = fullfile(data_dir, recording_folder);
save_dir_ball_cam = fullfile(save_dir_top, 'ball_camera');
save_dir_antenna_cam = fullfile(save_dir_top, 'antenna_camera');

% Make the data saving folders and catch potential data overwrites
check_for_dir = false;
if ~exist(save_dir_top, 'dir')
    mkdir(save_dir_top)
    mkdir(save_dir_ball_cam)
    mkdir(save_dir_antenna_cam)
else
    if check_for_dir
        error([save_dir_top ' already exists, potentially overwriting data!'])
    end
end

%% Configure the NI DAQs for measuring camera and speaker signals
D = daq.createSession('ni');
D.Rate = 50e3;
D.IsContinuous = true;

for i = 1:n_speakers
    chs_speakers(i) = D.addAnalogInputChannel('Dev2',i-1,'voltage');
    chs_speakers(i).TerminalConfig = 'Differential';
end

% Ball Camera Exposure channel (input from camera), 'Port0/Line9' = second NI breakout box PO1
D.addDigitalChannel('Dev2', 'Port0/Line9', 'InputOnly');

% Antenna Camera Exposure channel (input from camera), 'Port0/Line11' = second NI breakout box PO3
D.addDigitalChannel('Dev2', 'Port0/Line11', 'InputOnly');

% Use a callback function on DataAvailable to log data to .dat file
temp_log_filepath = fullfile(save_dir_top,'temp_logfile.dat');
temp_log_file_id = fopen(temp_log_filepath,'w+');
D.addlistener('DataAvailable',@(src,evt)io.logDaqData(src,evt,temp_log_file_id));

%% Configure Speakers
[speaker_devs, ~, audio_ids] = io.getSpeakerDevNames(n_speakers); 
speaker_rate = stim(1).sample_rate;

for i = 1:n_speakers
    Speakers(i) = daq.createSession('directsound'); %#ok<*SAGROW>
    Speakers(i).UseStandardSampleRates = false; %#ok<*UNRCH>
    Speakers(i).Rate = speaker_rate;
    
    AO(i) = Speakers(i).addAudioOutputChannel(speaker_devs(i).ID,1,'Audio');
end

% The rate should now be set to generation_rate, but double check since hardware overrides sometimes occur
if Speakers(1).Rate ~= speaker_rate
    error(['Speaker Rate is NOT ' num2str(speaker_rate) ', check configuration in Seraph 8+ settings'])
end

%% Run through stimulus reps
% save one .mat file for each condition and repetition in a trial structure
n_stimuli = length(stim);
num_reps = 10;
randomize = true;
do_half_stimuli = false;

% Iterate through all of the combinations
for i_rep = 1:num_reps
    
    fprintf('Rep: %0.2d / %0.2d | ', i_rep, num_reps)
    rep_str = sprintf('rep_%0.2d',i_rep);

    fprintf('\n\tAcquiring from DAQ\n. ')
    temp_log_file_id = io.clearLogFileData(temp_log_file_id,temp_log_filepath);
    % Queue one array for each camera (even if only using 1)
    D.startBackground();

    
    disp('PRESS START RECORDING IN SPINVIEW AND PRESS PLAY, then press any button to continue')
    pause()
    
    if randomize
        stim_order = randperm(n_stimuli);
    else
        stim_order = 1:n_stimuli;
    end
    
    if do_half_stimuli
        stim_order = stim_order(1:(n_stimuli/2));
        n_stimuli = n_stimuli/2;
    end
    
    data_save_str = ['daq_data_' rep_str];

    for i_stim = 1:n_stimuli
        curr_stim_ind = stim_order(i_stim);
        fprintf('Stim num %d %0.2d / %0.2d | ', curr_stim_ind, i_stim, n_stimuli)
        stim_str = sprintf('stim_%0.5d',curr_stim_ind);
        curr_stim = stim(curr_stim_ind);

        fprintf(' Sending from DAW\n.')
        
        % Send data over sound card (via DAW)        
        Speakers(curr_stim.curr_speaker).queueOutputData(curr_stim.speaker_stimulus');
        Speakers(curr_stim.curr_speaker).startForeground();
        
    end
    
    disp('PRESS STOP (red square) THEN, STOP RECORDING IN SPINVIEW AND  then press any button to continue')
    pause()
    
    % Stop background acquisition
    D.stop();
    fprintf(' Done with DAQ.\n')

    % Read in the data from logfile and reformat for simple saving
    fclose(temp_log_file_id);
    temp_log_file_id = fopen(temp_log_filepath,'r+');
    daq_data = fread(temp_log_file_id,'double');
    daq_data = reshape(daq_data, 11, []);
    daq_data = daq_data(2:end,:); % Remove timestamps (known fs)

    fprintf(' Saving...')

    % Save data
    save(fullfile(save_dir_top,[data_save_str '.mat']),'daq_data','-v6')

    % Clear logfile before next stimulus
    temp_log_file_id = io.clearLogFileData(temp_log_file_id,temp_log_filepath);

    fprintf(' Done\n')
    
    % Store some values in a metadata struct
    exp_meta(i_rep).fly_genotype = fly_genotype;
    exp_meta(i_rep).fly_dob = fly_dob;
    exp_meta(i_rep).stim_type = stim_type;
    exp_meta(i_rep).datestring = ds;

    exp_meta(i_rep).speaker_rate = speaker_rate;
    exp_meta(i_rep).acquisition_rate = D.Rate;

    exp_meta(i_rep).frame_rate = frame_rate;

    exp_meta(i_rep).speaker_rate = speaker_rate;
    exp_meta(i_rep).speaker_amp_value_db = speaker_amp_value_db;
    exp_meta(i_rep).daw_out_amp = daw_out_amp;

    exp_meta(i_rep).num_reps = num_reps;
    exp_meta(i_rep).randomize = randomize;
    exp_meta(i_rep).stim_order = stim_order;
    exp_meta(i_rep).datestring_end = datestr(now,30);
end

save(fullfile(save_dir_top,'exp_meta.mat'),'exp_meta');
