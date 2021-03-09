function toggle_template(ts, model, editor)
    import begonia.logging.log
    
    TKEY = "roa_template";

    if length(ts) ~= 1
        msgbox("Need to select one TSeries")
        return
    end
    
    % if var exists and is true, we turn it off:
    if ts.has_var(TKEY)
        roa_template = ts.load_var(TKEY);
        if roa_template 
            ts.save_var(TKEY, false)
            return
        end
    end
    
    % if key did not exist, or was negative, we need to establish, and must
    % first check if all required properties are set for the tseries to
    % work as a template:
    if ~ts.has_var("roa_pre_param")
        msgbox("TSeries cannot be used a template unless it's pre-processing parameters are set. Use automatic or manual pre-processing config.");
        return
    end
    
    if ~ts.has_var("roa_param")
        msgbox("TSeries does not have processing parameter set. To use as a template, pre-process + select tresholds");
        return
    end
    
    ts.save_var(TKEY, true)
end

