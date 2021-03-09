function drift_correction_trace = extract_drift_correction(ts)
    import begonia.logging.*;

    log(1, "Drift correction : " + ts.path);

    % Get a trace to calculate drifting on
    if ~ts.has_var("channel_traces")
        begonia.processing.roi.extract_chan_traces(ts);
    end
    drift_trace = ts.load_var("channel_traces");

    drift_trace_t = drift_trace.Time;
    drift_trace = drift_trace.Data(:,1);
    drift_correction_trace_t = drift_trace_t;

    % Remove outliers (usually panactivations)
    sigma = std(drift_trace);
    mu = mean(drift_trace);
    I = drift_trace > mu + 2*sigma;
    I = begonia.util.broaden_positives(I, ts.dt,5);
    drift_trace_t(I) = [];
    drift_trace(I) = [];

    % Drift corretion / fitting
    coeff = polyfit(drift_trace_t,drift_trace,1);

    drift_correction_trace = coeff(end)./polyval(coeff,drift_correction_trace_t);

    str = sprintf('df/f0 drift at end of signal = %.3f', drift_correction_trace(end)-1);
    log(1,str);

    ts.save_var("drift_correction_trace")
end
