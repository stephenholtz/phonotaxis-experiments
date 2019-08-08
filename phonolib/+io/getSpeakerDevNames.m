function [speaker_devs, sorted_out_names, audio_ids]= getSpeakerDevNames(n_speakers)
    % Check Installation: display all DAQ intervaces, NI and Seraph 8
    % requires installing device drivers, then MATLAB sound card support
    % https://www.mathworks.com/hardware-support/sound-card-daq.html
    devs = daq.getDevices;
    all_names = {devs.Model};
    % Find all daw outputs
    tokens = regexp(all_names,'DAW Out.*(.\d+)-(\d+).*\ MARIAN Seraph 8\+\)','tokens');
    token_inds = find(~cellfun(@isempty,tokens));
    
    % Sort daw outputs
    outs = [];
    for i = token_inds
        n1 = str2double(tokens{i}{1}{1});
        n2 = str2double(tokens{i}{1}{2});

        outs = [outs;n1,n2]; %#ok<*AGROW>
    end

    % The DAW channels that correspond to speaker output are configured in the 
    % Seraph 8 Manager. Should be the first 8 channels (DAW Out  1-2, through
    % DAW Out 15-16). Each channel is in stereo by default.
    [~,I] = sort(outs(:,1));
    token_inds_sort = token_inds(I);
    sorted_out_names = all_names(token_inds_sort);
    sorted_out_devs = devs(token_inds_sort);
    speaker_devs = sorted_out_devs(1:n_speakers);
    
    audio_ids = {speaker_devs.ID};
end