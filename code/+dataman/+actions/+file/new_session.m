function new_session(dloc, model, editor)
    model.dlocs = begonia.data_management.DataLocation.empty;
    editor.datagrid.reloadTable();
	editor.session_file = "";
end

