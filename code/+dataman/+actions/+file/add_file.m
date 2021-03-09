function add_file(dloc, model, editor)
    [p, d] = uigetfile("*.*");
    if p == 0
        return;
    end
    path = fullfile(d, p);
    
    h = waitbar(0.1, "Locating data (might take a while)");
    scans = begonia.scantype.find_scans(path);
    model.dlocs = [model.dlocs, scans];
    editor.datagrid.reloadTable();
    delete(h);
end

