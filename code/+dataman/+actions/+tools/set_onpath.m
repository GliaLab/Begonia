function set_onpath(tss, model, editor)
    for ts = begonia.util.to_loopable(tss) 
        engine = begonia.data_management.engine_from_path(ts.path);
        ts.dl_storage_engine = engine;
    end
    editor.datagrid.reloadTable();
end

