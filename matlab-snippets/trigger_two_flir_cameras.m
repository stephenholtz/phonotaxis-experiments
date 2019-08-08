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

%% Configure the NI DAQs for measuring camera and speaker signals
D = daq.createSession('ni');
D.Rate = 50e3;
D.IsContinuous = false;

D.addAnalogInputChannel('Dev2',0,'voltage');

% Ball Camera Trigger channel (output to the camera), 'Port0/Line8' = second NI breakout box PO0
D.addDigitalChannel('Dev2', 'Port0/Line8', 'OutputOnly');
% Ball Camera Exposure channel (input from camera), 'Port0/Line9' = second NI breakout box PO1
D.addDigitalChannel('Dev2', 'Port0/Line9', 'InputOnly');

% Antenna Camera Trigger channel (output to the camera), 'Port0/Line10' = second NI breakout box PO2
D.addDigitalChannel('Dev2', 'Port0/Line10', 'OutputOnly');
% Antenna Camera Exposure channel (input from camera), 'Port0/Line11' = second NI breakout box PO3
D.addDigitalChannel('Dev2', 'Port0/Line11', 'InputOnly');

%% Generate trigger array
frame_rate = 100;
duration_s = 60*15;
[trigger_array, n_triggers] = io.makeTriggerArray(frame_rate, duration_s, D.Rate);

pad_duration_s = 1;
trigger_pad = zeros(pad_duration_s * D.Rate, 1);

trigger_array_padded = [trigger_pad; trigger_array];

%% Send triggers to both cameras
fprintf('Sending triggers to cameras...')
D.queueOutputData([trigger_array_padded, trigger_array_padded]);
daq_data = D.startForeground();
fprintf('Done\n')

%%
exposure_out_1 = daq_data(:,2);
exposure_out_2 = daq_data(:,3);

%%
plot(exposure_out_1(1:D.Rate*5))
hold on;
plot(exposure_out_2(1:D.Rate*5))

legend('Exposure 1','Exposure 2')
%% 
frame_starts_1 = find(diff(exposure_out_1) > 0);
frame_starts_2 = find(diff(exposure_out_2) > 0);

n_detected_1 = sum(diff(exposure_out_1) > 0);
n_detected_2 = sum(diff(exposure_out_2) > 0);

fprintf('Triggers Sent: %d\nTriggers Recd 1: %d\nTriggers Recd 2: %d\n',n_triggers,n_detected_1,n_detected_2)
