function segtab = classifier_to_segtab(clfr, dt, cats,do_idcats)
    import begonia.util.to_loopable;
    
    if nargin < 4 ,do_idcats = false; end
    
    seg_start_s = [];
    seg_end_s = [];
    seg_category = categorical();
    seg_id = [];
    id_cat = "Seg-";
    
    for category = to_loopable(cats)
        clfr_bin = clfr == category;
        comps = bwconncomp(clfr_bin);
        if comps.NumObjects < 1; continue; end   
        
        if do_idcats, id_cat = string(category); end
        
        [ss, es, trg,id] = cellfun(@(p) pixlist_to_time(p, dt, category,id_cat)...
            , comps.PixelIdxList);
        
        seg_start_s = [seg_start_s ss];
        seg_end_s = [seg_end_s es];
        seg_category = [seg_category trg];
        seg_id = [seg_id id];
    end
    
    segtab = table(seg_id',seg_category', seg_start_s', seg_end_s');
    segtab.Properties.VariableNames = ...
        ["seg_id","seg_category", "seg_start_s", "seg_end_s"];
end

function [s, e, target,id] = pixlist_to_time(pl, dt, target,id_cat)
    s = pl(1) * dt;
    e = pl(end) * dt;
    id = string(begonia.util.make_snowflake_id(id_cat));
end