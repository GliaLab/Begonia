function clean_temporary_files(ts)
    import begonia.logging.log;

    for channel = 1:ts.channels
        log(1, ts.name + " : CH" + channel);
        maskfile = fullfile(ts.path, "roa_mask_ch" + channel + ".h5");
        recfile = fullfile(ts.path, "roa_recording_ch" + channel + ".h5");
        
        if exist(maskfile, "file")
            delete(maskfile);
        end
        
        if exist(recfile, "file")
            delete(recfile);
        end
    end
    
    % clear hidden params to allow re-processing:
    ts.clear_var("roa_param_hidden");
    ts.clear_var("roa_pre_param_hidden");
end

