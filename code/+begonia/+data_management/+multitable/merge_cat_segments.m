function tab = merge_cat_segments(segs)
    tab = table();

    % MERGE_CAT_SEGMENTS  Merges segments in same category for each entity
    ents = string(unique(segs.entity))';
    
    % find each entity
    for ent = ents
        ent_rows = segs(segs.entity == ent,:);
        
        % for each category:
        cats = string(unique(ent_rows.category))';
        for category = cats
            cat_rows = ent_rows(ent_rows.category == category,:);
            if height(cat_rows) ~= length(unique(cat_rows.seg_start_f))
                error("Multiple segments with same start frame - additional filtering of rows needed? (e.g. only provide on ca-compartment?)")
            end
            
            % compose merged result:
            row = cat_rows(1,:);
            row.trace = {vertcat(cat_rows.trace{:})};
            row.duration_s = sum(cat_rows.duration_s);
            row.seg_end_f = missing;
            row.seg_start_f = missing;
            row.seg_start_abs = missing;
            
            tab = vertcat(tab, row);
        end
        
    end
end

