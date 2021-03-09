function toMatfile( dlocs, model, editor)
    [fname,fpath] = uiputfile('All metadata.mat', 'Save file name (extention sets type)');
    if fname == 0
       return 
    end
    
    fullpath = fullfile(fpath, fname);
    
    
    data = struct();
    data.exported = datetime();
    data.file = fullpath;
    data.items = [];

    for dloc = model.selected
        dloc_data = dlocToStruct(dloc, model.selected_vars, model);
        data.items = [data.items ; dloc_data];
    end

    save(fullpath, 'data');
    disp(['Export done - wrote: ' fullpath]);

end


function s = dlocToStruct(dloc, vars, model)
    s = struct();
    for var = vars
        var = char(var);
        s.(var) = model.load(dloc, var);
    end
    s;
end