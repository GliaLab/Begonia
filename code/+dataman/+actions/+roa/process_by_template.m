function process_by_template(ts, model, editor)
    import begonia.processing.roa.*;
    import begonia.logging.log;

    % find selected: 
    log(1, "Detecting template " + ts.name);
    found_cnt = 0;
    for ts_sel = begonia.util.to_loopable(model.selected)
        if ts_sel.has_var("roa_template") 
            roa_template = ts_sel.load_var("roa_template");
            if roa_template
                found_cnt = found_cnt + 1;
                if found_cnt > 1 
                    error("Selection needs to include only one tseries with 'roa_template' flag set to true")
                else
                    ts_template = ts_sel;
                end
            end
        end
    end
    
    if found_cnt < 1 
        error("Selection must include one tseries with the 'roa_template' flag set to true");
    end
    
    % apply template's parameters to our tseries:
    % (and yes, this means we'll re-apply it to the template)
    roa_pre_param = ts_template.load_var("roa_pre_param");
    roa_param = ts_template.load_var("roa_param");
    
    % if roa_param exists, and has a ignore area setting, we transfer that:
    if ts.has_var("roa_param")
        oldp = ts.load_var("roa_param");
        if isfield(oldp, "roa_ignore_mask")
            for n = 1:length(roa_param)
                roa_param(n).roa_ignore_mask = oldp(n).roa_ignore_mask;
            end
        end
        if isfield(oldp, "roa_ignore_border")
            for n = 1:length(roa_param)
                roa_param(n).roa_ignore_border = oldp(n).roa_ignore_border;
            end
        end
    end

    ts.save_var("roa_pre_param");
    ts.save_var("roa_param");
    
    % enable re-processing:
    ts.clear_var("roa_param_hidden");
    ts.clear_var("roa_pre_param_hidden");
    
    % perform the processing:
    log(1, "Processing " + ts.name);
    pre_process(ts, editor.get_misc_config('roa_recording_folder'));
    filter_roa(ts,editor.get_misc_config('roa_recording_folder'));
    clean_temporary_files(ts);
end

