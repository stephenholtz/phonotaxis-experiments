function [directory] = lookupDirectories(dir_type)
% Centralize the directories for different experimental purposes
    data_dir = 'G:\phonotaxis_data';
    stim_dir = 'C:\code\phonotaxis-rig-experiments\stimuli';
    calib_dir = 'C:\code\phonotaxis-rig-experiments\calibration';

    switch dir_type
        case 'data'
            directory = data_dir;
        case {'stim','stimulus','stim_dir'}
            directory = stim_dir;
        case {'calib','calibration','calib_dir'}
            directory = calib_dir;
        otherwise
            error('Directory type not specified')
    end

end