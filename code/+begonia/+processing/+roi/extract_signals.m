function extract_signals(tss)
    import begonia.processing.roi.*;
    import begonia.logging.log;
    import begonia.util.*;
    
    for ts = to_loopable(tss)
        log(1, "Extacting all signals: " + ts.name)
        
        % all these function depend on the roi table:
        if ~ts.has_var("roi_table")
            error("Timeseries has no marked RoIs")
        end
        
        % perform extraction:
        extract_roi_signals(ts);
        extract_roi_dff_signals(ts);
        extract_neuron_doughnut_signals(ts);
        extract_channel_traces(ts);
        extract_drift_correction(ts);
    end
end

