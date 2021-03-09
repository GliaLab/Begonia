function clearSelected(dlocs, model, editor)

    % check user wants this for realz:
     check = questdlg(['Are you sure you want to clear variables: ' ...
         join(model.selected_vars, ", ")]); 
     if(~strcmp('Yes', check))
         return;
    end
    
    % clear the vars:
    for dloc = dlocs
        for varname = model.selected_vars
            dloc.clear_var(char(varname));
        end
        model.notifyChanged(dloc, varname, []);
    end
    
end

