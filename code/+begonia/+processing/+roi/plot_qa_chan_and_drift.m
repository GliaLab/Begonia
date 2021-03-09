function fig = plot_chan_and_drift(tss)
    for ts = tss
        fig = figure("color", [0.84,0.90,0.95], "name", "Channel traces and drift " + ts.name ); 
        drift = ts.load_var("drift_correction_trace");
        chan = ts.load_var("channel_traces");
        
        layout = tiledlayout(2,1);
        nexttile();
        plot(chan);
        title("Channel traces");
        legend;
        
        nexttile();
        plot(drift);
        title("Drift");
    end
end

