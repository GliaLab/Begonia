function configure_stabilize(dloc, model, editor)
    if exist("NoRMCorreSetParms") ~= 2
        msgbox("Error: NoRMCOrre is not installed - see documentation.");
        return;
    end

    if length(dloc) > 1
        ts = dloc(1); 
    else
        ts = dloc;
    end

    if ts.has_var('normcore_config')
        settings = ts.load_var('normcore_config');
    else
        settings = begonia.processing.motion_correction.AlignmentSettings(ts);
    end
    
    dialog = begonia.processing.motion_correction.NoRMCorreConfigurator(settings);
    addlistener(dialog ...
        , 'on_save' ...
        , @(~,~) save_all(dloc, dialog.settings, model,dialog.dialog));
end

% callback for saving to all provided tseries
function save_all(tseries, settings, model,dialog)
    begonia.logging.log(1,'Saving motion correction settings');
    for ts = tseries
        model.save(ts, 'normcore_config', settings)
    end
    close(dialog.figure)
end