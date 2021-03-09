function load_session(dloc, model, editor, file)
    import dataman.support.*;

    if nargin < 4
        [file, path] = uigetfile("Open catalogue file");
        if file == 0
            return;
        end
        file = fullfile(path, file);
    end
    
    
    load(file, "dlocs");
    model.dlocs = dlocs;
    editor.datagrid.reloadTable();
    
    editor.session_file = file;
    remember_session(editor);
end

