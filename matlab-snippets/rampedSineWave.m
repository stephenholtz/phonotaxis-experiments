function [mod_tone,ts_seconds] = rampedSineWave(sine_freq, amplitude, sine_duration, ramp_duration, sample_rate)
    len = (sine_duration * sample_rate) + (4*ramp_duration * sample_rate);
    ts = 0:(len-1);
    tone = amplitude*sin(sine_freq * ts/sample_rate * 2*pi);
    ramp = sin((0:(ramp_duration * sample_rate-1))*pi/2 / (ramp_duration * sample_rate)).^2;
    mod_tone = (tone .* [zeros(1, (ramp_duration * sample_rate)) ramp ones(1, sine_duration*sample_rate)...
        fliplr(ramp) zeros(1,(ramp_duration * sample_rate))])';
    ts_seconds = ts / sample_rate;
end