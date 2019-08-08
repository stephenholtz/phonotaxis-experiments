function [int_x_pos, int_y_pos, speed, timestamps, delta_rot_x, delta_rot_y, delta_rot_z] = importFictracDatFile(filename)
% Import data from dat file.
    delimiter = ',';
    formatSpec = '%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%[^\n\r]';

    % Open the text file.
    fileID = fopen(filename,'r');

    % Read columns of data according to the format.
    dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'TextType', 'string', 'EmptyValue', NaN,  'ReturnOnError', false);
    fclose(fileID);

    % rename some variables
    int_x_pos = dataArray{15};
    int_y_pos = dataArray{16};
    speed = dataArray{19};
    timestamps = dataArray{22};
    
    delta_rot_x = dataArray{6};
    delta_rot_y = dataArray{7};
    delta_rot_z = dataArray{8};