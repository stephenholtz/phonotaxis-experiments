% Prepare session
clearvars       % Clear variables  
clc             % Clean command window
daq.reset()     % Restart daq 
close all force % Close windows and interfaces

% Explicitly set path here
addpath(genpath('C:\code\phonotaxis-rig-experiments'))

% Remind to use internal clock, hopefully this ends up being overkill
warndlg('In SERAPH 8+ settings, configure to use internal clock!')

% Which speaker is being tested, this corresponds to a particular DAW
% output and DAQ signal copy input that is handled below (and stored)
speaker_tested = 1;

% Top level data saving directory
data_dir = 'D:\particle_velocity_calibration';

% Specific day, speaker calibration recording folder
ds = datestr(now,30);
recording_folder = [ds(1:8) '_speaker_' sprintf('%0.2d',speaker_tested)];
save_dir = fullfile(data_dir, recording_folder);

% Make the data saving folder
check_for_dir = false;
if ~exist(save_dir, 'dir')
    mkdir(save_dir)
else
    if check_for_dir
        error([save_dir ' already exists, potentially overwriting data!'])
    end
end

%% Identify and Make "Speaker" interfaces with windows DirectSound interface
[speaker_devs,speaker_names] = getSpeakerDevNames();

n_speakers = 8;
% 96kHz is sufficient for all stim freqs. The higher frequency sine waves
% are not especially distorted.
generation_rate = 192e3;

for i = 1:n_speakers
    Speakers(i) = daq.createSession('directsound'); %#ok<*SAGROW>
    Speakers(i).UseStandardSampleRates = false; %#ok<*UNRCH>
    Speakers(i).Rate = generation_rate;
    
    AO(i) = Speakers(i).addAudioOutputChannel(speaker_devs(i).ID,1,'Audio');
    AO(i).Name = speaker_names{i};
end

% The rate should now be set to generation_rate, but double check since
% hardware overrides sometimes occur
calib_meta.speakerRate = Speakers(1).Rate;

if calib_meta.speakerRate ~= generation_rate
    error(['Speaker Rate is NOT ' num2str(generation_rate) ', check configuration in Seraph 8+ settings'])
end

%% Make a nidaq analog input session for acquirign speaker command "copies"
AI = daq.createSession('ni');
% Sampling needs to be >2x generation 96kHz*2 ~ 200kHz
AI.Rate = 200e3;
AI.IsContinuous = true;
for i = 1:n_speakers
    chs_speakers(i) = AI.addAnalogInputChannel('Dev2',i-1,'voltage');
    chs_speakers(i).TerminalConfig = 'Differential';
end
%chs_speakers = AI.addAnalogInputChannel('Dev2',speaker_tested-1,'voltage');
%chs_speakers(1).TerminalConfig = 'Differential';

% Use a callback function on DataAvailable to log data to .dat file
temp_log_filepath = fullfile(save_dir,'temp_logfile.dat');
temp_log_file_id = fopen(temp_log_filepath,'w+');
AI.addlistener('DataAvailable',@(src,evt)logDaqData(src,evt,temp_log_file_id));

% PV should be on analog input 18
microphone_ch = 18;
chs_microphone = AI.addAnalogInputChannel('Dev2',[microphone_ch],'voltage');
chs_microphone(1).TerminalConfig = 'Differential';

%% Capture metadata for calibration
calib_meta.speakerTested = speaker_tested;
calib_meta.DawTested = speaker_names{calib_meta.speakerTested};
calib_meta.AnalogInputRate = AI.Rate;

% speaker setting, the knob on the front
calib_meta.speaker_amp_value_db = 18;

% preamp settings
calib_meta.preamp_vendor = 'Stanford Research Systems';
calib_meta.preamp_model = 'SR560';
calib_meta.preamp_bp_low = 10; % 10 hz cleans things up remarkably well
calib_meta.preamp_bp_high = 3e3; % bp high should be < 2.5x sample rate
calib_meta.preamp_bp_low_rolloff_db = 6; % less aggressive rolloff option
calib_meta.preamp_bp_high_rolloff_db = 6; % less aggressive rolloff option
calib_meta.preamp_gain = 50; % only setting that works for all intensities

% microphone settings
calib_meta.mic_id = 'k1';
calib_meta.mic_kv = 3*10^-4;

% misc settings
v = ver('MATLAB');
calib_meta.matlab_ver = v.Version;
calib_meta.datestr = datestr(now,30);

% Seraph 8+ mixer settings
calib_meta.daw_out_amp = '+6db';

% stimulus settings
testing = true;
if testing
    % Subset for testing acquisition etc.,
    calib_meta.frequencies_tested = 225;
    calib_meta.amplitudes_tested = 1;
    calib_meta.sine_duration = 5;
    calib_meta.ramp_duration = 0.25;
    calib_meta.n_reps = 2;
else
    calib_meta.frequencies_tested = 25:25:1000;
    calib_meta.amplitudes_tested = .25:.25:1;
    calib_meta.sine_duration = 0.5;
    calib_meta.ramp_duration = 0.25;
    calib_meta.n_reps = 4;
end

% Print total duration, should try to keep it <15 mins (b/c need to do 8x!)
total_dur_s = calib_meta.n_reps * numel(calib_meta.frequencies_tested) * ...
                                  numel(calib_meta.amplitudes_tested) * ...
                                  (calib_meta.ramp_duration + calib_meta.sine_duration);
fprintf('Total Duration : %.2f mins\n',total_dur_s/60)

%% Run through calibration reps
% save one .mat file for every condition and repetition since we cannot yet
% control the timing for the direct-sound device... 

num_freqs = numel(calib_meta.amplitudes_tested);
num_amps = numel(calib_meta.amplitudes_tested);
num_reps = calib_meta.n_reps;

% Save metadata before stimuli (incase of early termination)
save(fullfile(save_dir,'pv_meta.mat'),'calib_meta','-v6')

% Iterate through all of the combinations
for i_rep = 1:num_reps
    fprintf('Rep: %0.2d / %0.2d | ', i_rep, num_reps)
    rep_str = sprintf('rep_%0.2d',i_rep);
    
    for i_freq = 1:num_freqs
        curr_freq = calib_meta.frequencies_tested(i_freq);
        fprintf('Freq: %0.4d Hz  %0.2d / %0.2d | ',curr_freq, i_freq, num_freqs)
        freq_str = sprintf('%0.4d_hz',curr_freq);

        for i_amp = 1:num_amps
            curr_amp = calib_meta.amplitudes_tested(i_amp);
            fprintf('Amp: %0.2d%%  %0.2d / %0.2d | ',100*curr_amp, i_amp, num_amps)
            amp_str = sprintf('%0.2d_pct_amp',100*curr_amp);
            
            full_str = ['pv_' freq_str '_' amp_str '_' rep_str];
            
            sine_wave = rampedSineWave(curr_freq, curr_amp, ...
                                       calib_meta.sine_duration,...
                                       calib_meta.ramp_duration,...
                                       calib_meta.speakerRate);
            %offset = (0.016*(50/75))/2;
            offset = 0;
            sine_wave = sine_wave - offset;
            fprintf('\n\tAcquiring from DAQ. ')

            % Record on DAQ (without triggering) to log file
            temp_log_file_id = clearLogFileData(temp_log_file_id,temp_log_filepath);
            AI.startBackground();
            
            fprintf(' Sending from DAW.')
            
            % Send data over sound card (via DAW)
            Speakers(speaker_tested).queueOutputData(sine_wave);
            Speakers(speaker_tested).startForeground();
            
            % Stop background acquisition
            AI.stop(); % delete(lh);
            fprintf(' Done.')
            
            % Read in the data from logfile and reformat for simple saving
            fclose(temp_log_file_id);
            temp_log_file_id = fopen(temp_log_filepath,'r+');
            daq_data = fread(temp_log_file_id,'double');
            daq_data = reshape(daq_data,numel(chs_microphone)+numel(chs_speakers)+1,[]);
            daq_data = daq_data(2:end,:); % Remove timestamps (known fs)
            
            fprintf(' Saving...')

            % Save data
            save(fullfile(save_dir,[full_str '.mat']),'daq_data','-v6')
            
            % Clear logfile before next stimulus
            temp_log_file_id = clearLogFileData(temp_log_file_id,temp_log_filepath);
            
            fprintf(' Done\n')

        end
    end
end
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


%% Local Functions
function logDaqData(~,evt,fid)
    % Create a callback fuction for writing data
    data = [evt.TimeStamps, evt.Data]';
    % precision is only single
    fwrite(fid,data,'double');
end

function new_fid = clearLogFileData(temp_log_file_id,temp_log_filepath)
    % Close and re-open so that it overwrites content ('w+')
    [~] = fclose(temp_log_file_id);
    new_fid = fopen(temp_log_filepath,'w+');
end

function [mod_tone,ts_seconds] = rampedSineWave(sine_freq, amplitude, sine_duration, ramp_duration, sample_rate)
    len = (sine_duration * sample_rate) + (4*ramp_duration * sample_rate);
    ts = 0:(len-1);
    tone = amplitude*sin(sine_freq * ts/sample_rate * 2*pi);
    ramp = sin((0:(ramp_duration * sample_rate-1))*pi/2 / (ramp_duration * sample_rate)).^2;
    mod_tone = (tone .* [zeros(1, (ramp_duration * sample_rate)) ramp ones(1, sine_duration*sample_rate)...
        fliplr(ramp) zeros(1,(ramp_duration * sample_rate))])';
    ts_seconds = ts / sample_rate;
end

function [speaker_devs,sorted_out_names]= getSpeakerDevNames()
    % Check Installation: display all DAQ intervaces, NI and Seraph 8
    % requires installing device drivers, then MATLAB sound card support
    % https://www.mathworks.com/hardware-support/sound-card-daq.html
    devs = daq.getDevices;
    all_names = {devs.Model};
    % Find all daw outputs
    tokens = regexp(all_names,'DAW Out (.\d+)-(\d+).*\ MARIAN Seraph 8\+\)','tokens');
    token_inds = find(~cellfun(@isempty,tokens));
    %disp(allModels(tokenInds)');
    % Sort daw outputs
    outs = [];
    for i = token_inds
        n1 = str2double(tokens{i}{1}{1});
        n2 = str2double(tokens{i}{1}{2});
        outs = [outs;n1,n2]; %#ok<*AGROW>
    end

    % The DAW channels that correspond to speaker output are configured in the 
    % Seraph 8 Manager. Should be the first 8 channels (DAW Out  1-2, through
    % DAW Out 15-16). Each channel is in sterio by default.
    [~,I] = sort(outs(:,1));
    token_inds_sort = token_inds(I);
    sorted_out_names = all_names(token_inds_sort);
    sorted_out_devs = devs(token_inds_sort);
    speaker_devs = sorted_out_devs(1:8);
end
