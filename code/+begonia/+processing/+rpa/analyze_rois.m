function analyze_rois(ts)
    import begonia.logging.log;

    % check stuff is ok to go:
    if ~ts.has_var("roi_table")
        error("TSeries missing roi array or roa mask: "...
            + ts.name + ", " + ts.path)
    end

    % sum active pixels pr. roi pr. frame. RoA masks exists for more
    % than once channel, and since the masks can be heavy to load, we
    % do this on a pr. channel basis:
    roi_table = ts.load_var('roi_table');

    % pre-allocate the resulting array:
    signal_rpa_pct = cell(height(roi_table), 1);

    for chan = 1:ts.channels
        roi_ch_idxs = find(roi_table.channel == chan)';
        if isempty(roi_ch_idxs); continue; end

        % do we actually have a RoA mask for this channel?
        mask_var = "roa_mask_ch" + chan;
        if ~ts.has_var(mask_var)
            warning("Cannot extract RoA mask for rois in channel " + chan ...
                + ". Do you need to run processing and pre-processing on this tseries?") 
            continue;
        end

        log(1, "CH" + chan + ": processing RPA signals");
        roa_mask = ts.load_var(mask_var);

        % find the rois that belong to this channel, and process those.
        % The RPA is calculated by looking at each frae of the RoA
        % mask, and counting how many active pixels are inside the RoIs
        % pr. frame. This is the RPA - RoI pixel activity.
        for idx = roi_ch_idxs
            roi = roi_table(idx,:);
            sub_mask = roa_mask & roi.mask{:}; % only overlaping pixels remain

            % reduces dimentions 1-by-1 by summing: 
            active_pixels = squeeze(sum(sum(sub_mask,2), 1))';
            rpa_pct = active_pixels ./ roi.area_px2;
            signal_rpa_pct(idx) = {rpa_pct};
        end
    end

    % write results:
    roi_id = roi_table.roi_id;
    roi_signals_rpa = table(roi_id, signal_rpa_pct);
    ts.save_var("roi_signals_rpa");
end

