%% Rough processing script for analyzing fictrac data
% will output a portable structure that we can analyze on any computer
clearvars;
addpath(genpath('C:\code\phonotaxis-rig-experiments'))

cont_acq_dir = 'G:\phonotaxis_data\Continuous_acquisition';
exp_folders = {'20190710T180002_pip_trains_01_CS',... 
               '20190711T205502_pip_trains_01_CS',...
               '20190711T220956_pip_trains_01_CS',...
               '20190711T235214_pip_trains_01_CS'};
curr_exp_num = 4;

% full filepath to the experiment
curr_exp_folder = fullfile(cont_acq_dir,exp_folders{curr_exp_num});
disp(curr_exp_folder)

%% Load each of the data sources that we need for processing next

% Load the exp_meta file
exp_meta_file = dir([curr_exp_folder filesep 'exp_meta.mat']);
exp_meta_file = ([exp_meta_file(1).folder filesep exp_meta_file(1).name]);
load(exp_meta_file);

% Load all the *.mat files into a cell array
daq_data_files = dir([curr_exp_folder filesep 'daq*.mat']);
daq_data = {};
for i = 1:length(daq_data_files)
    daq_data_file = ([daq_data_files(i).folder filesep daq_data_files(i).name]);
    loaded_data = load(daq_data_file); %#ok<*SAGROW>
    daq_data{i} = loaded_data.daq_data; % pull out the loaded 
end

% Get all the fictrac .dat files
fictrac_dat_files = dir([curr_exp_folder filesep 'ball_camera' filesep '*.dat']);
fictrac_data = struct;
for i = 1:length(fictrac_dat_files)
    fictrac_data_file = ([fictrac_dat_files(i).folder filesep fictrac_dat_files(i).name]);
    
    [int_x_pos, int_y_pos, speed, timestamps, delta_rot_x, delta_rot_y, delta_rot_z] = io.importFictracDatFile(fictrac_data_file);
    fictrac_data(i).int_x_pos =  int_x_pos;
    fictrac_data(i).int_y_pos =  int_y_pos;
    fictrac_data(i).speed =  speed;
    fictrac_data(i).timestamps =  timestamps;
    fictrac_data(i).abs_rot_x =  delta_rot_x;
    fictrac_data(i).abs_rot_y =  delta_rot_y;
    fictrac_data(i).abs_rot_z =  delta_rot_z;
end

%% Parse the frame exposures within each repetition
ball_cam_exposure_ind = 9;

% each loop is a single repetition in this case
camera_exposures = {};
frame_start_inds = {};
n_rep_frames = {};
for i_rep = 1:length(daq_data)
    camera_exposures{i_rep} = daq_data{i_rep}(ball_cam_exposure_ind,:);
    % find all the where the logic level switches 
    frame_start_inds{i_rep} = find(diff((camera_exposures{1})) == 1);
    
    % let's make the assumption that "extra" frames all happened at the end of
    % the experiment here
    n_fictrac_frames = length(fictrac_data(i_rep).int_x_pos);
    n_frame_starts = length(frame_start_inds{i_rep});

    % take the lesser of the two for idexing reasons
    n_rep_frames{i_rep} = min(n_fictrac_frames,n_frame_starts);
    
    frame_start_inds{i_rep} = frame_start_inds{i_rep}(1:n_rep_frames{i_rep});
end

%% take the speaker data that actually matter from the daq_data cell array
left_speaker_ind = 4;
right_speaker_ind = 6;
speaker_data = struct();
for i_rep = 1:length(daq_data)
    speaker_data.left{i_rep} = daq_data{i_rep}(left_speaker_ind,:);
    speaker_data.right{i_rep} = daq_data{i_rep}(right_speaker_ind,:);
end

(exp_meta(1).stim_order);

%% Parse the speaker signals using the tiny artifact!!

% Find all the times where there is a threshold crossing in the difference
% up to the time where there is the opposite threshold crossing, AND there
% is not another difference for some period (as to not confuse with sound)
artifact_diff_thresh = 0.025;

% number of samples that will separate artifacts but not be able to
% separate the sound signals
sound_min_sep_thresh_starts = 100000; 
sound_min_sep_thresh_stops = 150000;

stim_inds = struct();
for i_rep = 1:length(daq_data)
    for curr_speaker = 1:2
        if curr_speaker == 1
            speaker_name = 'left';
        else
            speaker_name = 'right';
        end
        bl_est = median(speaker_data.(speaker_name){i_rep}(1:1000));
        speaker_bs = speaker_data.(speaker_name){i_rep} - bl_est;

        % Find threshold crossings after baseline subtraction
        stim_start_drity_inds = find(diff([bl_est, speaker_bs]) > +artifact_diff_thresh);
        stim_stop_dirty_inds = find(diff([bl_est, speaker_bs]) < -artifact_diff_thresh);

        % throw away diffs that are due to sounds, leaving just those from stimulus starting and stopping
        valid_start_bool = (diff([0 stim_start_drity_inds]) > sound_min_sep_thresh_starts);
        valid_stop_bool = (diff([stim_start_drity_inds(1) stim_stop_dirty_inds]) > sound_min_sep_thresh_stops);

        stim_start_inds = stim_start_drity_inds(valid_start_bool);
        stim_stop_inds = stim_stop_dirty_inds(valid_stop_bool);

        % finally, remove all the remaining points where there are stops
        % detected in error. starts are robust
        stim_inds(i_rep).(speaker_name) = {};
        for i_start = 1:numel(stim_start_inds)
            curr_start_ind = stim_start_inds(i_start);

            % go through the stop positions until one is appropriately far away
            valid_stop_pos = false;
            i_stop = i_start;
            while ~valid_stop_pos
                curr_stop_ind = stim_stop_inds(i_stop);
                if (curr_stop_ind - curr_start_ind) > sound_min_sep_thresh_starts
                    valid_stop_pos = true;
                else
                    i_stop = i_stop + 1;
                end
            end
            stim_inds(i_rep).(speaker_name){i_start} = [curr_start_ind, stim_stop_inds(i_stop)];
        end
    end
end

%% Now merge the left and right speakers, lookup stimulus numbers
for i_rep = 1:length(daq_data)
    for i_left = 1:length(stim_inds(i_rep).left)
        left_stim_starts(i_left) = stim_inds(i_rep).left{i_left}(1);
        left_stim_stops(i_left) = stim_inds(i_rep).left{i_left}(2);
    end
    left_speakers = 4*ones(length(stim_inds(i_rep).left),1);
    
    for i_right = 1:length(stim_inds(i_rep).right)
        right_stim_starts(i_right) = stim_inds(i_rep).right{i_right}(1);
        right_stim_stops(i_right) = stim_inds(i_rep).right{i_right}(2);
    end
    right_speakers = 6*ones(length(stim_inds(i_rep).left),1);
    
	all_stim_starts = [left_stim_starts, right_stim_starts];
	all_stim_stops = [left_stim_stops, right_stim_stops];
	all_stim_speakers = [left_speakers, right_speakers];
    
    [~,I] = sort(all_stim_starts);
    
    all_stim_inds{i_rep} = [all_stim_starts(I);all_stim_stops(I)]';
    all_stim_nums{i_rep} = exp_meta(i_rep).stim_order;
    % Keep track of which speaker goes with which stimulus as a sanity chekc
    all_stim_speaker_nums{i_rep} = all_stim_speakers(I);
end

%% Compile final struct with these fields
% start and stop inds for the stimulis
% speaker timeseries
% exposure timeseries
% stimulus number 
% speaker number 

% exp_data(stim_num,rep_num).xxx
exp_data = struct();

for i_rep = 1:length(daq_data)
    curr_stim_order = all_stim_nums{i_rep};
    for i_stim = 1:numel(curr_stim_order)
        curr_stim_num = curr_stim_order(i_stim);
        
        exp_data(curr_stim_num,i_rep).stimulus_number = curr_stim_num;
        speaker_number = all_stim_speaker_nums{i_rep}(i_stim);
        exp_data(curr_stim_num,i_rep).speaker_number = speaker_number;
        
        start_stop_ind = all_stim_inds{i_rep}(i_stim,:);
        exp_data(curr_stim_num,i_rep).start_stop_ind = start_stop_ind;
        
        % extract the speaker timeseries        
        if speaker_number == 4
            speaker_name = 'left';
        elseif speaker_number == 6
            speaker_name = 'right';
        end
        
        bl_est = median(speaker_data.(speaker_name){i_rep}(1:10000));
        speaker_bs = speaker_data.(speaker_name){i_rep} - bl_est;
        exp_data(curr_stim_num,i_rep).speaker_stim = speaker_bs(start_stop_ind(1):start_stop_ind(2));
        n_speaker_samps = length(exp_data(curr_stim_num,i_rep).speaker_stim);
        speaker_ts = (1:n_speaker_samps)/exp_meta(i_rep).acquisition_rate;
        exp_data(curr_stim_num,i_rep).daq_ts = speaker_ts;
        
        % extract exposure data (as a sanity signal)
        exp_data(curr_stim_num,i_rep).cam_exposure = daq_data{i_rep}(ball_cam_exposure_ind,start_stop_ind(1):start_stop_ind(2));
        
        start = start_stop_ind(1);
        stop = start_stop_ind(2);

        fictrac_frame_inds = 1:numel(frame_start_inds{i_rep});
        curr_frame_bool = (frame_start_inds{i_rep} > start) & (frame_start_inds{i_rep} < stop);
        curr_frame_inds = frame_start_inds{i_rep}(curr_frame_bool);
        
        exp_data(curr_stim_num,i_rep).int_x_pos = fictrac_data(i_rep).int_x_pos(curr_frame_bool);
        exp_data(curr_stim_num,i_rep).int_y_pos = fictrac_data(i_rep).int_y_pos(curr_frame_bool);
        exp_data(curr_stim_num,i_rep).speed = fictrac_data(i_rep).speed(curr_frame_bool);
        exp_data(curr_stim_num,i_rep).timestamps = fictrac_data(i_rep).timestamps(curr_frame_bool);
        
        exp_data(curr_stim_num,i_rep).abs_rot_x = fictrac_data(i_rep).abs_rot_x(curr_frame_bool);
        exp_data(curr_stim_num,i_rep).abs_rot_y = fictrac_data(i_rep).abs_rot_y(curr_frame_bool);
        exp_data(curr_stim_num,i_rep).abs_rot_z = fictrac_data(i_rep).abs_rot_z(curr_frame_bool);
        
        n_frames = sum(curr_frame_bool);
        dur_s = exp_data(curr_stim_num,i_rep).daq_ts(end);
        frame_rate = n_frames/dur_s;
        fictrac_ts =(1:n_frames)/frame_rate;
        exp_data(curr_stim_num,i_rep).fictrac_ts = fictrac_ts;
        
    end
end

save(fullfile(curr_exp_folder,[exp_folders{curr_exp_num} '_exp_data.mat']),'exp_data');