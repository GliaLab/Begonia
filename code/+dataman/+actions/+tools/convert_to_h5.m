function convert_to_h5(ts, model, editor)
    [d,f] = fileparts(ts.path);
    output_path = fullfile(d,[f,' H5.h5']);
    
    begonia.scantype.h5.tseries_to_h5(ts,output_path);
    
    ts_new = begonia.scantype.find_scans(output_path);
    editor.add_dlocs(ts_new);
end

