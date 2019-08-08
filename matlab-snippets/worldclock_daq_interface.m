%% Test the "World Clock" synchronization for the Marian Seraph 8 MXW


%%
daq.reset()
S = daq.createSession('ni');

%%
S.addDigitalChannel('Dev2','Port0/Line0','OutputOnly');
S.Rate = 10e3; 
S.addAnalogInputChannel('Dev2',0,'Voltage');

%%
% dur_s = 10;
% t = 0:(1/S.Rate):dur_s;
% out = square((2*pi*10e3)*t);
% out(out<0) = 0;
% out = out';

dur_s = 5;
n_samps = 2;
out = [ones(n_samps, dur_s/(n_samps*2) * S.Rate); zeros(n_samps, dur_s/(n_samps*2) * S.Rate)];
out = out(:);

S.queueOutputData(out);
S.startForeground()