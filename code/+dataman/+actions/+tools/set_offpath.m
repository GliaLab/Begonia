function set_offpath(tss, model, editor)
    dstore = uigetdir(pwd(), "Select off-path root directory");
    for ts = begonia.util.to_loopable(tss) 
        ts.dl_storage_engine = begonia.data_management.OffPathEngine(dstore);
    end
    editor.datagrid.reloadTable();
end
