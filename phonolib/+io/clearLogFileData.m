function new_fid = clearLogFileData(temp_log_file_id,temp_log_filepath)
    % Close and re-open so that it overwrites content ('w+')
    [~] = fclose(temp_log_file_id);
    new_fid = fopen(temp_log_filepath,'w+');
end