function add(dloc, model, editor)
    path = uigetdir("Select root of data directory");
    if path == 0
        return;
    end
    
    h = waitbar(0.1, "Locating data (might take a while)");
    scans = begonia.scantype.find_scans(path);
    model.dlocs = [model.dlocs, scans];
    editor.datagrid.reloadTable();
    delete(h);
end

