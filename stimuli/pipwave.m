function [mod_tone,ts_seconds] = pipwave(sine_freq, amplitude, sine_duration, sample_rate)
    len = sine_duration * sample_rate;
    ts = 0:(len-1);
    tone = amplitude * sin(sine_freq * ts/sample_rate * 2*pi);
    mod_ts = linspace(0,pi,len);
    mod_tone = sin(mod_ts).*tone;
    ts_seconds = ts / sample_rate;
end