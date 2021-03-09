
function segtab = segment_entity(traces, clfr_cat, pos_cats)
    if isstring(pos_cats); pos_cats = categorical(pos_cats); end

    traces.tmp_id = (1:height(traces))';

    % we're performing separate segmentation for each entity:
    ents = unique(traces.entity);
    segs = arrayfun(@(ent) entity_segtab(traces, ent, clfr_cat, pos_cats)...
        , ents ...
        , "UniformOutput", false);

    segs = vertcat(segs{:});

    traces.trace = [];
    traces.seg_category = [];
    traces.seg_start_f = [];
    traces.seg_end_f = [];
    traces.seg_start_abs = [];

    segtab = join(segs, traces);
    segtab.tmp_id = [];

end
% each gets their own segmentation table:


function segs = entity_segtab(traces, entity, clfr_cat, pos_cat)
    import begonia.data_management.multitable.classifier_to_segtab;

    traces_ent = traces(traces.entity == entity,:);
    clfr = traces_ent(traces_ent.category == clfr_cat,:);
    if isempty(clfr)
        error(entity + ": Could not segment. Each entity needs classifier trace: " + clfr_cat);
    end
    
    if height(clfr) > 1
        error(entity + ": Could not segment. Each entity needs precicely 1 trace of type classifier");
    end
    
    segtab = classifier_to_segtab(clfr.trace{:}, clfr.trace_dt, pos_cat);
    
    segs = arrayfun(@(id, srctr, dt, abs_start) process_row(id, srctr, dt, abs_start, segtab) ...
        , traces_ent.tmp_id, traces_ent.trace, traces_ent.trace_dt, traces_ent.seg_start_abs ...
        , "UniformOutput", false);
    
    segs = vertcat(segs{:});
end

function rowsegs = process_row(id, srctr, dt, abs_start, segtab)
    srctr = srctr{:};

    seg_start_abs = seconds(segtab.seg_start_s) + abs_start;
    seg_start_f = ceil(segtab.seg_start_s / dt);
    seg_end_f = ceil(segtab.seg_end_s / dt);
    seg_end_f(seg_end_f > length(srctr)) = length(srctr);
    tmp_id = repmat(id, size(seg_start_f));
    seg_category = segtab.seg_category;
    
    trace = arrayfun(@(s, e) srctr(s:e) ...
        , seg_start_f, seg_end_f...
        , "UniformOutput", false);
    
    rowsegs = table(tmp_id, trace, seg_category, seg_start_abs, seg_start_f, seg_end_f);
end
