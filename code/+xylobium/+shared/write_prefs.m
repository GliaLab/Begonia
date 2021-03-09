function write_prefs(namespace, key, value)
    file = fullfile(prefdir, namespace);
    if ~exist(file, "file")
        prefs = struct();
    else
        prefs = load(file, "prefs");
    end
    prefs.(key) = value;
    save(file, "prefs");
end

