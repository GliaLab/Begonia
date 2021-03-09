function stabilize(ts, model, editor)
    if exist("NoRMCorreSetParms") ~= 2
        msgbox("Error: NoRMCOrre is not installed - see documentation.");
        return;
    end
    
    if ts.has_var('normcore_config')
        config = ts.load_var('normcore_config');
    else
        config = begonia.processing.motion_correction.AlignmentSettings(ts);
    end
    
    % Save the stabilized tseries at the same location but with
    % "_stabilized" added to the filename. 
    [d,f] = fileparts(ts.path);
    output_path = fullfile(d,[f,'_stabilized']);
    
    ts_stabilized = begonia.processing.motion_correction.run_normcorre(ts,output_path,config,'h5');
    editor.add_dlocs(ts_stabilized);
end

