function segtab = segment_globally(traces, clfr, dt, cats,do_idcats)
    import begonia.util.to_loopable;
    import begonia.data_management.multitable.classifier_to_segtab;
    
    if nargin < 5, do_idcats = false; end

    if isstring(cats)
        cats = categorical(cats);
    end
   
    traces.tmp_id = (1:height(traces))';
    
    % for global segmenting, we segment all traces by same segtab:
    segtab = classifier_to_segtab(clfr, dt, cats,do_idcats);
    segs = arrayfun(@(id, t, dt, absst) process_row(id, t, dt, absst, segtab) ...
        , traces.tmp_id, traces.trace, traces.trace_dt, traces.seg_start_abs ...
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

function rowsegs = process_row(id, srctr, dt, abs_start, segtab)
    srctr = srctr{:};

    seg_start_abs = seconds(segtab.seg_start_s) + abs_start;
    seg_start_f = ceil(segtab.seg_start_s / dt);
    seg_end_f = ceil(segtab.seg_end_s / dt);
    seg_end_f(seg_end_f > length(srctr)) = length(srctr);
    tmp_id = repmat(id, size(seg_start_f));
    seg_category = segtab.seg_category;
    seg_id = segtab.seg_id;
    
    trace = arrayfun(@(s, e) srctr(s:e) ...
        , seg_start_f, seg_end_f...
        , "UniformOutput", false);
    
    rowsegs = table(tmp_id, trace, seg_id, seg_category, seg_start_abs, seg_start_f, seg_end_f);
end

