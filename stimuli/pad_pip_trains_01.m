clearvars;

% Explicitly set path here
addpath(genpath('C:\code\phonotaxis-rig-experiments'))

% Top level data saving directory
data_dir = io.lookupDirectories('data');
stim_dir = io.lookupDirectories('stim');
calib_dir = io.lookupDirectories('calib');


fp = 'C:\code\phonotaxis-rig-experiments\stimuli\pip_trains_01';
load(fp)

sample_rate = 192000;
for i = 1:numel(stim)
   stim(i).speaker_stim = [stim(i).speaker_stim zeros(1,sample_rate*6)];
end

save(fullfile(calib_dir,'pip_trains_01.mat'),'stim')