function [train_stim, train_ts] = make_pip_train(pip_freq, particle_vels, sample_rate)
% Inputs:
%   pip_freq -
%   particle_vels -
% Outputs:
%
    sine_duration = 0.03;
    dur_bn_pips_s = 0.03;
    dur_bn_pips_samps = dur_bn_pips_s * sample_rate;
    [mod_tone, ~] = pipwave(pip_freq, particle_vels, sine_duration, sample_rate);

    pip_stim = [zeros(1,dur_bn_pips_samps), mod_tone];

    train_stim = repmat(pip_stim, 1, 10);

    n_samps_stim = length(train_stim);

    train_ts = 1:n_samps_stim;
    train_ts=train_ts/sample_rate;

end