function remove_selected(to_remove, model, editor)

    all = model.dlocs;
    filtered = [];
    for ts = begonia.util.to_loopable(all)
        if ~any(to_remove == ts)
            filtered = [filtered ts]; %#ok<AGROW>
        end
    end
    
    model.dlocs = filtered;
    editor.datagrid.reloadTable();
end

