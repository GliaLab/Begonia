function tptab = timerange(traces, from_s, to_s)
    if ~isa(from_s, "duration") | ~isa(to_s, "duration")
        error("from_s and to_s must be durations");
    end

    tptab = traces;
    [tptab.trace, tptab.seg_start_f, tptab.seg_end_f] = ...
       arrayfun(@(trace, dt) process(trace, dt, from_s, to_s)...
       , traces.trace, traces.trace_dt ...
       , "UniformOutput", false);

    tptab.seg_start_abs = tptab.seg_start_abs + seconds(from_s);

    sz = size(tptab.trace);
    tptab.seg_category = repmat("range", sz);
end

function [subtrace, start_f, end_f] = process(trace, dt, from_s, to_s)
    trace = trace{:};
    from_s = seconds(from_s);
    to_s = seconds(to_s);
    
    start_f = ceil(from_s / dt);
    end_f = ceil(to_s / dt);
    
    if start_f < 1
        error("Delta time is wrong - start frame is less than 1 after conversion");
    end
    
    if end_f > length(trace)
        error("Delta time is wrong, or trace is too short for en time: " + end_f + " < " + length(trace))
    end
    
    subtrace = trace(start_f:end_f);
end