function val = read_prefs(namespace, key, default)
    file = fullfile(prefdir, namespace);
    if ~exist(file, "file")
        val = default;
        return;
    end    
    
    prefs = load(file).prefs;
    if ~isfield(prefs, key)
        val = default;
        return;
    end
    
    val = prefs.(key);
end

