function copy_to_offpath(ts, model, editor)
    offpath_eng = ts.dl_storage_engine;
    if ~isa(offpath_eng, "begonia.data_management.OffPathEngine")
        error("tseries must currently use off-path engine for this operation to work");
    end
    
    offpath_dir = ts.dloc_metadata_dir;
    
    % temporarily change engine to identify the metadata dir:
    onpath_eng = begonia.data_management.engine_from_path(ts.path);
    
    ts.dl_storage_engine = onpath_eng;
    onpath_dir = ts.dloc_metadata_dir;
    
    % restore original engine:
    ts.dl_storage_engine = offpath_eng;
    
    % copy the contents of the onpath to offpath, but make a backup:
    timestamp = string(datestr(now,"_yyyymmdd_HHMMSS"));
    backup_offpath_dir = offpath_dir + "_backup" +  timestamp;
    if exist(offpath_dir, "dir")
        movefile(offpath_dir, backup_offpath_dir);
    end
    
    copyfile(onpath_dir, offpath_dir)
    
end

