%% Load data from alex
load('C:\code\phonotaxis-rig-experiments\calibration\pv_mic_calibration\freqVsKE.mat');

% using a container?
freqs_mc = keys(k1Map);
kvals_mc = values(k1Map,freqs_mc);

% convert to vectors
freqs = [freqs_mc{:}];
kvals = [kvals_mc{:}];
%%
% Units for KE are Volts * s^2 / m

% determined from https://wilson.hms.harvard.edu/files/wilson-lab/files/lehnertwilson2013_som.pdf

% figure
% plot(freqs,kvals)

% 
% %%
% rate = calib_meta.AnalogInputRate;
% t_stop = 8339277;
% t_start = 8080123;
% 
% mic_data = calib_data{1,1}(2,t_start:t_stop);
% mic_data = mic_data - mean(mic_data);
% 
% particle_vel = mic_data / mean(kvals);
% particle_vel = particle_vel / rate;
% particle_vel_mm = particle_vel * 1000;
% 
% disp(max(particle_vel_mm))

%%
rate = calib_meta.AnalogInputRate;

t_stop = 8339277;
t_start = 8080123;

mic_data = mic_data{1,2}(2,:);
mic_data = mic_data - mean(mic_data);

particle_vel = mic_data / mean(kvals);
particle_vel = particle_vel / rate;
particle_vel_mm = particle_vel * 1000;

disp(max(particle_vel_mm))