function table_rpa = extract_signals(tss)
    %{
    ROI PIXEL ACTIVITY (RPA)
    This module loads each roi of a ts, then multiplies each frame in roa
    mask with the roi, and counts remaining active pixels.
    %}
    import begonia.util.*;
    import begonia.logging.log;

    for ts = to_loopable(tss)

        log(1, "Processing rois");
        if ts.has_var("roi_table")
            begonia.processing.rpa.analyze_rois(ts);
        else
            log(1, "Missing roi_table - only FOV analysis will be done");
        end
        
        % extract compartment:
        log(1, "Processing compartments");
        begonia.processing.rpa.extract_compartment_signals(ts);
    end
end



