function channel_traces = extract_channel_traces(ts)
    begonia.logging.log(1, "Creating channel traces : " + ts.path);

    traces = nan(ts.frame_count,ts.channels);

    for i = 1:ts.channels
        mat = ts.get_mat(i);
        c = begonia.util.Chunker(mat);
        for j = 1:c.chunks
            mat_sub = c.chunk(j);
            I = c.chunk_indices(j);
            I = I{3};
            traces(I,i) = mean(mean(mat_sub,1),2);
        end
    end

    t = (0:(size(traces,1)-1))*ts.dt;
    t = t';
    channel_traces = timeseries(traces,t,"Name", "channel_traces");
    assert(~isnan(channel_traces.TimeInfo.Increment));
    ts.save_var("channel_traces")
end