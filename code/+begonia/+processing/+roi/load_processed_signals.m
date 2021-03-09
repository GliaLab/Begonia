function signals = load_processed_signals(tss)
    import begonia.util.*;

    signals = table();
    for ts = to_loopable(tss)
        roi_table = ts.load_var("roi_table");

        % load the RoIs:
        signal = ts.load_var("roi_signals_raw");
        signal_dff = ts.load_var("roi_signals_dff");
        signal_doughnut = ts.load_var("roi_signals_doughnut");

        rois = join(roi_table, signal);
        rois = join(rois, signal_dff);
        rois = join(rois, signal_doughnut);
        
        signals = [signals ; rois];
    end
end

