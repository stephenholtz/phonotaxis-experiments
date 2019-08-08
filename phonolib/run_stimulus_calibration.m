% Prepare session
clearvars       % Clear variables  
clc             % Clean command window
daq.reset()     % Restart daq 
close all force % Close windows and interfaces

% Explicitly set path here
addpath(genpath('C:\code\phonotaxis-rig-experiments'))

% Which speaker is being tested, this corresponds to a particular DAW
% output and DAQ signal copy input that is handled below (and stored)
speaker_to_test = 6;

% Top level data saving directory
data_dir = io.lookupDirectories('data');
stim_dir = io.lookupDirectories('stim');
calib_dir = io.lookupDirectories('calib');

% Select which stimulus to load and deliver
stim_type = 1;
switch stim_type
    case 1
        stim_name = 'pip_trains_01';
    otherwise
        error('Stimulus type not specified')
end
load(fullfile(stim_dir,stim_name));

%% Configure Speakers
n_speakers = 8;
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

current_speaker = speaker_to_test(1);

%% Make a nidaq analog input session for acquirign speaker command "copies"
AI = daq.createSession('ni');
% Sampling needs to be >2x generation 96kHz*2 ~ 200kHz
AI.Rate = 100e3;
AI.IsContinuous = true;

chs_speakers(1) = AI.addAnalogInputChannel('Dev2',current_speaker-1,'voltage');
chs_speakers(1).TerminalConfig = 'Differential';

% Use a callback function on DataAvailable to log data to .dat file
temp_log_filepath = fullfile(calib_dir,'temp_logfile.dat');
temp_log_file_id = fopen(temp_log_filepath,'w+');
AI.addlistener('DataAvailable',@(src,evt)io.logDaqData(src,evt,temp_log_file_id));

% PV should be on analog input 18
microphone_ch = 18;
chs_microphone = AI.addAnalogInputChannel('Dev2',[microphone_ch],'voltage');
chs_microphone(1).TerminalConfig = 'Differential';

%% Capture metadata for calibration
calib_meta.speakerTested = current_speaker;
calib_meta.AnalogInputRate = AI.Rate;

% speaker setting, the knob on the front
calib_meta.speaker_amp_value_db = 0;

% preamp settings
calib_meta.preamp_vendor = 'Stanford Research Systems';
calib_meta.coupling = 'DC';
calib_meta.preamp_model = 'SR560';
calib_meta.preamp_bp_low = 3e3; % 10 hz cleans things up remarkably well
calib_meta.preamp_bp_high = 10; % bp high should be < 2.5x sample rate
calib_meta.preamp_bp_low_rolloff_db = 6; % less aggressive rolloff option
calib_meta.preamp_bp_high_rolloff_db = 6; % less aggressive rolloff option
calib_meta.preamp_gain = 50; % only setting that works for all intensities

% microphone settings
calib_meta.mic_id = 'k1';
calib_meta.mic_kv = 3*0^-4;

% misc settings
v = ver('MATLAB');
calib_meta.matlab_ver = v.Version;
calib_meta.datestr = datestr(now,30);

% Seraph 8+ mixer settings
calib_meta.daw_out_amp = '+6db';

% Save metadata before stimuli (incase of early termination)
save(fullfile(calib_dir,'pv_meta.mat'),'calib_meta','-v6')

%% Iterate through all of the combinations
num_reps = 4;

n_stimuli = length(precalib_stim);

amps_to_test = [0.1,0.4,0.7];
all_stimuli = {};

for i_rep = 1:5
    fprintf('Rep: %0.2d / %0.2d | ', i_rep, num_reps)
    rep_str = sprintf('rep_%0.2d',i_rep);
    
    for i_stim = 1:n_stimuli
        fprintf('Stim num %0.2d / %0.2d | ', i_stim, n_stimuli)
        
        for i_amp = 1:length(amps_to_test)
            
            curr_amp = amps_to_test(i_amp);
            
            stim_str = sprintf('stim_%0.5d',i_stim);
            curr_stim = precalib_stim(i_stim);

            fprintf('\n\tAcquiring from DAQ. ')

            temp_log_file_id = io.clearLogFileData(temp_log_file_id,temp_log_filepath);
            % Queue one array for each camera (even if only using 1)
            AI.startBackground();
            fprintf(' Sending from DAW.')
            
            % Send data over sound card (via DAW)
            scaled_stim = curr_amp *curr_stim.speaker_stimulus;

            Speakers(speaker_to_test).queueOutputData(scaled_stim');
            Speakers(speaker_to_test).startForeground();
            % Stop background acquisition
            AI.stop(); 
            fprintf(' Done.')

            % Read in the data from logfile and reformat for simple saving
            fclose(temp_log_file_id);
            temp_log_file_id = fopen(temp_log_filepath,'r+');
            daq_data = fread(temp_log_file_id,'double');
            daq_data = reshape(daq_data, 1 + 2, []);
            daq_data = daq_data(2:end,:); % Remove timestamps (known fs)
            
            all_stimuli{i_stim,i_amp,i_rep} = daq_data;
            
            fprintf(' Saving...')
            % Clear logfile before next stimulus
            temp_log_file_id = io.clearLogFileData(temp_log_file_id,temp_log_filepath);

            fprintf(' Done\n')
        end
    end
end

save(fullfile(calib_dir,[stim_name, '_speaker_', num2str(speaker_to_test) , '.mat']),'all_stimuli','-v6')

%% Quick plots
figure;

bs_sub = false;
if bs_sub
    daq_data_bs_sub = daq_data - mean(daq_data(:,1:100),2);
else
    daq_data_bs_sub = daq_data;
end
ax1 = subplot(211); 
plot(abs(daq_data_bs_sub)');
ax2 = subplot(212); 
plot(daq_data_bs_sub'); 
linkaxes([ax1,ax2],'x');