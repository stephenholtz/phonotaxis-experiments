%% Initalize / Acquisition Parameters
clearvars; clc; 
daq.reset();

samp_rate = 10000;
frame_rate_hz = 50;
% exposure duration needs to be slightly lower than frame rate allows
exposure_dur_s = 0.90*(1/frame_rate_hz);
exposure_time_us = exposure_dur_s * (1000^2) + 1; % the + 1 is always added by software
fprintf('exposure_time_us = %f (for %dHz fps)\n', exposure_time_us, frame_rate_hz)

%% Configure the PointGrey (FLIR) USB3 Camera (do both parts)
% (1) Camera configuration to allow external triggering:
%   Exposure Auto = "Off"
%   Trigger Mode = "On"
%   Exposure Time = `exposure_time_us`
%   Trigger Source = "Line 0" 
%   Trigger Activation = "Rising Edge"
%   Trigger Overlap = "Read Out"
%
% (2) Camera configuration to allow exposure readout:
%   Line Selector = "Line 1"
%   Line Mode = "Output"
%   Line Source = "Exposure Active"
%   Line Inverter = Checked (enabled)


% Line3 (Green, marked with black tape) is CAMERA output

%% Initalize DAQ channels
S = daq.createSession('ni');
S.Rate = samp_rate;

% Make Trigger channel (output to the camera)
% 'Port0/Line8' = second NI breakout box PO0
S.addDigitalChannel('Dev2', 'Port0/Line8', 'OutputOnly');

% Make Exposure channel (input from camera)
% 'Port0/Line9' = second NI breakout box PO1
S.addDigitalChannel('Dev2', 'Port0/Line9', 'InputOnly');

% Add an analog input to use the clock for the digital channels above
% get a clock in the mix from the analog channel
S.addAnalogInputChannel('Dev2',0,'Voltage');

disp('DAQ initialized')

%% Create and send triggering signals
acq_dur_s = 5;

% Make a single trigger of all zeros then just change a few samples to 1
trig = zeros((1/frame_rate_hz) * samp_rate,1);
trig(1:100) = 1;

% Repeat the single trigger for the desired acquisition time 
trig_array = repmat(trig, frame_rate_hz*acq_dur_s,1);

% Send the triggering array data to the DAQ for triggering
S.queueOutputData(trig_array);

daq_data = S.startForeground();
plot(daq_data)
