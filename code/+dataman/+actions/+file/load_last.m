function load_last(dloc, model, editor)
    import dataman.support.*;

    sessions = read_prefs("sessions", []);
    if isempty(sessions)
        msgbox("No known last saves");
        return;
    end
    
    file = sessions(1);
    if ~exist(file, "file")
        msgbox("Last saved session is moved or deleted. Cannot re-open.");
        return
    end
    
    load(file, "dlocs");
    model.dlocs = dlocs;
    editor.datagrid.reloadTable();
    
    % sets this to be current file:
    editor.session_file = file;
end

