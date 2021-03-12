function aligned = timealign(traces, alignment)
    if nargin < 2 
        alignment = "first";
    end
    
    if alignment ~= "first" && alignment ~= "last"
        error("alignment strategy must be 'first' or 'last' - see docs")
    end
    
    % prepare time alignment zero point:
    if alignment == "first"
        align_point = min(traces.seg_start_abs);
    else
        align_point = max(traces.seg_start_abs);
    end
    
    % adjust traces to aligment point:
    [new_traces, diff_f] = cellfun(@(t, s, dt) align_(t, s, dt, align_point) ...
        , traces.trace ...
        , num2cell(traces.seg_start_abs) ...
        , num2cell(traces.trace_dt)...
        , "UniformOutput", false);
    
    aligned = traces;
    aligned.trace = new_traces;
    aligned.seg_start_abs = repmat(align_point, size(aligned.seg_start_abs));
    aligned.seg_start_f = aligned.seg_start_f + [diff_f{:}]';
    aligned.seg_end_f = aligned.seg_end_f + [diff_f{:}]';
end

function [aligned, diff_f] = align_(trace, start, dt, point)
    diff_f = 0;
    aligned = trace;
    
    % 1) we are at alignment point:
    if start == point
        return;
    end
    
    % choose padding strategy:
    padd = nan;
    if ~isnumeric(trace) 
        padd = missing;
    end
    
    % calculate difference in frames:
    diff_s = seconds(start - point);
    diff_f = ceil(diff_s/dt);
    
    % 2) we are either ahead of the alignemnt point and need to cut, of we
    % are being and need to pad:
    if start < point
        aligned = trace(diff_f * -1:end);
    else
        padding = repmat(padd, 1, diff_f);
        if isrow(trace)
            aligned = [padding trace];
        else
            aligned = [padding' ; trace];
        end
    end       
end