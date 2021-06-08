function save_as_tiff(folder,folder_out,merged_frames)
if nargin < 3
    merged_frames = 1;
end

ts = begonia.scantype.find_scans(folder);

for i = 1:length(ts)
    
    new_ts_path = strrep(ts(i).path,folder,folder_out);
    
    begonia.scantype.tiff.tseries_to_tiff(ts(i),new_ts_path,merged_frames);
end

end

