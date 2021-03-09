function copy_single(dloc, model, editor)
    import begonia.logging.*;
    tic;

    if length(model.selected_values) > 1 || length(model.selected_vars) > 1
        msgbox('Need to select a single value only');
        return;
    end
    
    % load value, put into clipboard:
    var = char(model.selected_vars);
    editor.clipboard_value = model.load(dloc, var, false);
    log(1, ['Copied "' var '"']);
end

