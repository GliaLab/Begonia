function tab = resample(tab, target_dt)
  
    [new_traces, new_dt] = ...
        arrayfun(@(tr, dt) resample_internal([tr{:}], dt, target_dt) ...
        , tab.trace, tab.trace_dt ...
        , "UniformOutput", false);

    new_dt = [new_dt{:}]';

    tab.trace = new_traces;
    tab.trace_dt = [new_dt];
end


function [new_vec, new_dt] = resample_internal(vec, old_dt, new_dt)
    if new_dt == old_dt
        new_vec = vec;
        return;
    end

    vec_t = seconds((1:length(vec)) .* old_dt)';
    timetab = timetable(vec_t, vec);

    method = 'linear';
    endval = nan;
    
    non_numeric = islogical(vec) || iscategorical(vec);
    if non_numeric 
        method = 'nearest'; 
        had_nans = false;
        endval = 'extrap';
    else
        % if traces has nans, we need to resample those
        % separately, which feels silly.. but have not
        % found another way:
        had_nans = any(isnan(vec));
        if had_nans
            nan_idxs = isnan(vec);
            nan_timetab = timetable(vec_t, nan_idxs);
            nan_timetab = retime(nan_timetab, 'regular', 'nearest', 'TimeStep', seconds(new_dt));
        end
    end

    timetab = retime(timetab, 'regular', method, 'TimeStep', seconds(new_dt), "endvalues", endval);

    if non_numeric
        vec = logical(vec); 
    else
        % re-fill nans that were present before interpolation
        if had_nans
            vars = timetab.Variables;
            vars(nan_timetab.Variables) = nan;
            timetab.Variables = vars;
        end
    end

    new_vec = timetab.vec;
end
