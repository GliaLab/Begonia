function engine = engine_from_path(path)
    if isfolder(path)
        % if dloc is a folder, we store metadata there -> "on
        % path engine"
        engine = begonia.data_management.OnPathEngine();

    elseif isfile(path)
        % if the path is a file, we generate an adjacent folder
        % for the data -> "file path engine"
        [p, n] = fileparts(path);
        metadir = fullfile(p, char(n + ".metadata"));
        engine = begonia.data_management.FilePathEngine(metadir);
    else
        error("the path is neither a file nor a folder - dont know what to do ¯\_(ツ)_/¯");
    end
end

