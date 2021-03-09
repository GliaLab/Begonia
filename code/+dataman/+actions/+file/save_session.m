function save_session(dloc, model, editor, new_save)
    import dataman.support.*;

    % is this a new save?
    if editor.session_file == "" || new_save
        name = begonia.util.make_snowflake_id("Session");
        [file, path] = uiputfile(name + ".mat", "Save datalocations to catalogue file");
        if file == 0
            return;
        end
        editor.session_file = fullfile(path, file);
    end
    
    dlocs = model.dlocs;
    save(editor.session_file, "dlocs");
    
    % save this to prefs for easy re-open:
    remember_session(editor);
end

