function segtab = classifier_to_segtab(clfr, dt, cats)
    import begonia.util.to_loopable;
    
    seg_start_s = [];
    seg_end_s = [];
    seg_category = categorical();
    
    for category = to_loopable(cats)
        clfr_bin = clfr == category;
        comps = bwconncomp(clfr_bin);
        if comps.NumObjects < 1; continue; end
        
        [ss, es, trg] = cellfun(@(p) pixlist_to_time(p, dt, category)...
            , comps.PixelIdxList);
        
        seg_start_s = [seg_start_s ss];
        seg_end_s = [seg_end_s es];
        seg_category = [seg_category trg];
    end
    
    segtab = table(seg_category', seg_start_s', seg_end_s');
    segtab.Properties.VariableNames = ...
        ["seg_category", "seg_start_s", "seg_end_s"];
end

function [s, e, target] = pixlist_to_time(pl, dt, target)
    s = pl(1) * dt;
    e = pl(end) * dt;
end