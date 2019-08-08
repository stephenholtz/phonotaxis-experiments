% Use the Data Aquisition Toolbox and the windows directsound interface to
% control the Seraph 8+ sound card output. (Since the ASIO interface
% doesn't seem to work as expected). Snippet here to use as boilerplate.
%
% SH 2018
clear all 
close all
clc

%% Check Installation: display all DAQ intervaces, NI and Seraph 8
% requires installing device drivers, then MATLAB sound card support
% https://www.mathworks.com/hardware-support/sound-card-daq.html
devs = daq.getDevices;
allModels = {devs.Model};
% Find all daw outputs
tokens = regexp(allModels,'DAW Out (.\d+)-(\d+).*\(MARIAN Seraph 8\+\)','tokens');
tokenInds = find(~cellfun(@isempty,tokens));
%disp(allModels(tokenInds)');
% Sort daw outputs
outs = [];
for i = tokenInds
    n1 = str2double(tokens{i}{1}{1});
    n2 = str2double(tokens{i}{1}{2});
    outs = [outs;n1,n2]; %#ok<*AGROW>
end

% The DAW channels that correspond to speaker output are configured in the 
% Seraph 8 Manager. Should be the first 8 channels (DAW Out  1-2, through
% DAW Out 15-16). Each channel is in sterio by default.
[~,I] = sort(outs(:,1));
tokenIndsSort = tokenInds(I);
sortedOutModels = allModels(tokenIndsSort);
sortedOutDevs = devs(tokenIndsSort);
speakerDevs = sortedOutDevs(1:8);

%% Create sessions for each speaker
% https://www.mathworks.com/help/daq/ref/addaudiooutputchannel.html
for i = 1:8
    S(i) = daq.createSession('directsound');
    AO(i) = S(i).addAudioOutputChannel(sortedOutDevs(i).ID,1,'Audio');
    AO(i).Name = sortedOutModels{i};
end
disp(S)

%% Make a nidaq analog input session 
AI = daq.createSession('ni');
AI.Rate = 100e3;
AI.IsContinuous = true;
chs = AI.addAnalogInputChannel('Dev1',[0:7],'voltage');
for i = 1:numel(chs)
    chs(i).TerminalConfig = 'Differential';
end
disp(AI)
%% Make a short tone to play
fs = S(1).Rate;
freqHz = 150;
tLen = .5;
rampTime = 100;

len = tLen * fs + 4*rampTime;
ts = 0:(len-1);
tone = sin(freqHz * ts/fs * 2*pi)/2.5;
ramp = sin((0:(rampTime-1))*pi/2 / rampTime).^2;
modTone = (tone .* [zeros(1, rampTime) ramp ones(1, tLen*fs)...
    fliplr(ramp) zeros(1,rampTime)])';

%% Send a tone to each of the speakers
rec_output = true;
if rec_output
    % Record without triggering
    temp_log_filepath = fullfile(pwd,'temp_logfile.dat');
    temp_log_file_id = fopen(temp_log_filepath,'w+');   
    AI.addlistener('DataAvailable',@(src,evt)logDaqData(src,evt,temp_log_file_id));
    AI.startBackground();
end

for i = 1:8
    fprintf('Speaker %s playing...',AO(i).Name);
    S(i).queueOutputData(modTone);
    S(i).startForeground();
    fprintf('done\n');
end

if rec_output
    % Stop background acquisition
    AI.stop();
    
    % Read in the data from the logfile
    fclose(temp_log_file_id);
    temp_log_file_id = fopen(temp_log_filepath,'r');
    daq_data  = fread(temp_log_file_id,'double');
    daq_data  = reshape(daq_data,numel(chs)+1,[]);
    daq_data  = daq_data(2:end,:);    
    fclose(temp_log_file_id);
    
    figure;plot(daq_data');
end

%% Create a callback fuction for writing data
function logDaqData(~,evt,fid)
    data = [evt.TimeStamps, evt.Data]';
    % precision is only single
    fwrite(fid,data,'double');
end