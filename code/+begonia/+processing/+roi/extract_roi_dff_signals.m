function roi_signal_raw = extract_roi_dff_signals(ts)
    import begonia.logging.log;

    % we need to have the roi signals to perform this processing:
    if ~ts.has_var("roi_signals_raw")
        begonia.processing.roi.extract_roi_signal(ts);
    end
    
    log(1, "Extracting df_f0 roi signals: " + ts.name);

    roi_signal_raw = ts.load_var("roi_signals_raw");
    roi_table = ts.load_var("roi_table");
    
    roi_signal_raw = join(roi_signal_raw, roi_table);
    
    signal = vertcat(roi_signal_raw.signal_raw{:});

    % Calculate df/f0
    f0 = mode(round(signal), 2);
    signal = (signal ./ f0) - 1;  
    
    % create a joinable output table:
    roi_id = roi_table.roi_id;
    signal_dff = num2cell(signal, 2);
    roi_signals_dff = table(roi_id, signal_dff,f0);
    
    ts.save_var("roi_signals_dff");
    
end

