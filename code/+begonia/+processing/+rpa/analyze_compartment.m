function stats = analyze_compartment(ts, roa_mask, roi_mask)
    sub_mask = roa_mask & roi_mask;
    area_px2 = sum(roi_mask(:));
    
    % active fraction of region:
    active_fraction = squeeze(sum(sum(sub_mask, 2), 1))' / area_px2;
     
    % count event starting and ending in each frame:
    activities_started = zeros(1, ts.frame_count);
    activities_ended = zeros(1, ts.frame_count);
    activity_duration_sum = zeros(1, ts.frame_count);
    
    comps = bwconncomp(sub_mask);
    for i = 1:comps.NumObjects
        idxs = comps.PixelIdxList{i};

        % get indexes for each component - first and last of the z-axis eaqual
        % the start and end frame for that event:
        [~, ~, zs] = ind2sub(size(sub_mask), idxs);
        ev_start = min(zs);
        ev_end = max(zs);
        dur = ev_end - ev_start;

        % add to the frames to count the start/end of events:
        activities_started(ev_start) = activities_started(ev_start) + 1;
        activities_ended(ev_end) = activities_ended(ev_end) + 1;
        activity_duration_sum(ev_start) = activity_duration_sum(ev_start) + dur;
    end
    
    activity_mean_duration = activity_duration_sum ./ activities_started;

    % count components *in* each indicidual frame:
    active_area_cnt = zeros(1, ts.frame_count);
    active_event_cnt = zeros(1, ts.frame_count);
    
    for f = 1:ts.frame_count
        frame = sub_mask(:,:,f);
        cc = bwconncomp(frame);
        active_area_cnt(f) = cc.NumObjects;
    end
    
    % count events active in each frame:
    for i = 1:comps.NumObjects
        idxs = comps.PixelIdxList{i};

        % get indexes for each component - first and last of the z-axis eaqual
        % the start and end frame for that event:
        [~, ~, zs] = ind2sub(size(sub_mask), idxs);
        s = min(zs);
        e = max(zs);
        active_event_cnt(s:e) = active_event_cnt(s:e) + 1;
    end
    
    % collect it:
    stats = struct();
    stats.area_px2 = area_px2;
    stats.active_fraction = active_fraction;
    stats.new_events = activities_started;
    stats.finished_event = activities_ended;
    stats.active_area_cnt = active_area_cnt;
    stats.active_event_cnt = active_event_cnt;
    stats.activity_mean_duration = activity_mean_duration;
end