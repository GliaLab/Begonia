function val = read_prefs(key, default)
    file = fullfile(prefdir, "glab_dataman_prefs.mat");
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

