% Attempts to use the Audio Toolbox and the ASIO drivers provided by
% MARIAN. It doesn't seem like there is a straghtforward way to use
% these low latency interfaces with triggering and queueing like the
% Data Acquisition Toolbox Provides. Snippets left here in case useful
%
% SH 2018

%% Check Installation: display all DAQ intervaces, NI and Seraph 8
% requires installing device drivers, then MATLAB sound card support
% https://www.mathworks.com/hardware-support/sound-card-daq.html
D = daq.getDevices; disp(D)

%% Display ASIO settings popup for Seraph 8+ (DAW card)
% We can rename for ease of use and enable/disable interfaces
%  1) Select "Only the following devices are visible to this application"
%     and then check all playback devices
%  2) Change "Execution priority" to highest settings
%  3) change "Buffersize in Samples" to 1024 or higher
% Select OK
asiosettings

%% Configure a deviceWriter for a single channel out
% this works as defined in the documentation, but how to tie multiple
% channels together doesn't seem to be addressed here

% Change driver to ASIO to expose ASIO compatible devices
deviceWriter = audioDeviceWriter;

% display all ASIO driver available devices
% equivalent to devices = set(deviceWriter,'Device');
devices = getAudioDevices(deviceWriter);
disp(devices')

% Set to the device name string from getAudioDevices
deviceWriter.Device = 'DAW Out  1-2 (MARIAN Seraph 8+)';
deviceWriter.Driver = 'ASIO';
deviceWriter.SampleRate = 192*10^3;
disp(deviceWriter);

%% Alternatively configure deviceWriter to have just one object
% presumably this unifies all output somehow, but the method of yolking
% everything is not documented, and definitely not exposed by the Auido 
% Toolbox API
deviceWriter2 = audioDeviceWriter;

% first change the driver
deviceWriter2.Driver = 'ASIO';
devices2 = getAudioDevices(deviceWriter2);
disp(devices2')

% Set to the device name string from getAudioDevices
deviceWriter2.Device = 'ASIO Seraph 8';
deviceWriter2.SampleRate = 192*10^3;
disp(deviceWriter2);

%% Send signals to deviceWriter...

%%
fs = 192e3;
freqHz = 150;
tLen = 1;
rampTime = 100;

len = tLen * fs + 4*rampTime;
ts = 0:(len-1);
tone = sin(freqHz * ts/fs * 2*pi);
ramp = sin((0:(rampTime-1))*pi/2 / rampTime).^2;
modTone = (tone .* [zeros(1, rampTime) ramp ones(1, tLen*fs)...
    fliplr(ramp) zeros(1,rampTime)])';

%%
deviceWriter.play(modTone)
