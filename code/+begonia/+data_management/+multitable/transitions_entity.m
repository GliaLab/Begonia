function transtab = transitions_entity(traces, clfr_var, from, to, left_s, right_s)
    % assign each trace a ID we can use to join later:
    entities = unique(traces.entity)';
    traces.tmp_id = (1:height(traces))';

    % arrays to keep as we iterate - hard to preallocate this /:
    subtraces = cell.empty;
    transition_f = cell.empty;
    tmp_id = cell.empty;
    seg_start_abs = cell.empty;
    seg_start_f = cell.empty;
    seg_end_f = cell.empty;

    % for each entity, get it's traces and classifier. Then get the
    % transitions from that classifier, and cut each of the entity's traces
    % by the classifier:
    for entity = entities
        traces_ent = traces(traces.entity == entity,:);
        clfr = traces_ent(traces_ent.category == clfr_var,:);
        trans_ss = classifier_to_trans(clfr, from, to);

        for i = 1:height(traces_ent)
            trace = traces_ent(i,:);
            vec = trace.trace{:};
            dt = trace.trace_dt;

            for trans_s = trans_ss'
                trans_f = ceil(trans_s / dt);
                left_f = trans_f - ceil(left_s / dt);
                right_f = trans_f + ceil(right_s / dt);
                start_abs = trace.seg_start_abs + (seconds(trans_s) - seconds(left_s));

                if left_f < 1; left_f = 1; end
                if right_f > length(vec); right_f = length(vec); end

                subtrace = vec(left_f:right_f);

                transition_f = [transition_f ; {trans_f}];
                subtraces = [subtraces ; {subtrace}];
                tmp_id = [tmp_id ; {trace.tmp_id}];
                seg_start_abs = [seg_start_abs ; {start_abs}];
                seg_start_f = [seg_start_f ; left_f];
                seg_end_f = [seg_end_f ; right_f];
            end
        end
    end

    % clean up and join results with the temprary id, then remove it:
    trace = subtraces;
    tmp_id = cell2mat(tmp_id);
    transition_f = cell2mat(transition_f);
    seg_start_f = cell2mat(seg_start_f);
    seg_end_f = cell2mat(seg_end_f);
    seg_start_abs = [seg_start_abs{:}]';

    transtab = table(tmp_id, trace, transition_f, seg_start_abs, seg_start_f, seg_end_f);
    traces.trace = [];
    traces.transition_f = [];
    traces.seg_start_abs = [];
    traces.seg_start_f = [];
    traces.seg_end_f = [];

    transtab = join(transtab, traces);
    transtab.tmp_id = [];
    transtab.seg_category = repmat(from + " → " + to, size(transtab.seg_category));

end

function trans_s = classifier_to_trans(clfr, from, to)
    a = clfr.trace{:}(1:end-1);
    b = clfr.trace{:}(2:end);
    trans_f = find(a == from & b == to);
    trans_s = trans_f * clfr.trace_dt;
end
