%% Test multichannel:
% https://www.mathworks.com/help/daq/multichannel-audio-input-and-output.html
% https://www.mathworks.com/help/daq/ref/addaudiooutputchannel.html
clearvars; close all;
addpath(genpath('C:\code\phonotaxis-rig-experiments'))

% sample data makes `Fs` and `y`
load handel;
samp_rate = Fs; clear Fs
signal = y; clear y

%% Configure multispeaker with the Seraph
[speaker_devs, ~, audio_ids] = io.getSpeakerDevNames(); 
n_speakers = numel(speaker_devs);

SpeakerArray = daq.createSession('directsound');
SpeakerArray.Rate = samp_rate;

for i_id = 1:n_speakers
    % the speakers are individually addressable with 
    SpeakerArray.addAudioOutputChannel(audio_ids{i_id},1);
end

%%
data_out = repmat(signal,n_speakers);
SpeakerArray.queueOutputData(data_out);

%%
SpeakerArray.startForeground();
