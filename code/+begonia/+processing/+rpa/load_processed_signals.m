function rpa = load_processed_signals(tss)
    import begonia.util.*;

    rpa = table();
    for ts = to_loopable(tss)
        roi_signal_rpa = ts.load_var("roi_signal_rpa");
        roi_table = ts.load_var("roi_table");
    
        ts_rpa = join(roi_table, roi_signal_rpa);
        rpa = [rpa ; ts_rpa];
    end
end

