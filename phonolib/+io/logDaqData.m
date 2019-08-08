function logDaqData(~,evt,fid)
    % Create a callback fuction for writing data
    data = [evt.TimeStamps, evt.Data]';
    % precision is only single
    fwrite(fid,data,'double');
end