function comp_table = extract_compartment_signals(ts)
    import begonia.util.to_loopable;
    import begonia.processing.rpa.analyze_compartment;
    import begonia.logging.log;

    % use roi table, or an empy one if not present:
    roi_table = ts.load_var("roi_table", begonia.processing.roi.make_roi_table());
    
    % add FOV as a "roi" for all channels:
    fov = true(ts.img_dim);
    for ch = 1:ts.channels
        r = height(roi_table) + 1;
        roi_table.channel(r) = ch;
        roi_table.mask(r) = {fov};
        roi_table.type(r) = "FOV";
    end

    % for each channel:
    r = 1;
    for chan = to_loopable(unique(roi_table.channel))
        rtab_chan = roi_table(roi_table.channel == chan,:);
        mask = ts.load_var("roa_mask_ch" + chan, []);
        if isempty(mask); continue; end

        % grab data for each group of roi in this channel:
        for comp = to_loopable(unique(rtab_chan.type))
            log(1, ts.name + " CH" + chan + " " + comp);
            rtab_comp = rtab_chan(rtab_chan.type == comp,:);

            % basic data:
            comp_mask = sum(cat(3, rtab_comp.mask{:}), 3) == 1;
            compartment(r,:) = categorical(comp);
            ts_name(r,:) = categorical(string(ts.name));
            compartment_mask(r,:) = {comp_mask}; %#ok<*AGROW>
            
            % stats for the compartment:
            stats = analyze_compartment(ts, mask, comp_mask);
            
            channel(r,:) = chan;
            area_px2(r,:) = stats.area_px2;
            active_fraction(r,:) = {stats.active_fraction};
            new_events(r,:) = {stats.new_events};
            finished_events(r,:) = {stats.finished_event};
            active_area_count(r,:) = {stats.active_area_cnt};
            active_event_count(r,:) = {stats.active_event_cnt};
            new_event_duration(r,:) = {stats.activity_mean_duration};
            r = r + 1;
        end
    end
    
    compartment_signal = table(compartment, channel, ts_name, compartment_mask, area_px2, ...
        active_fraction, new_events, finished_events, active_area_count, active_event_count, new_event_duration);
    
    ts.save_var(compartment_signal);
end

