function write_prefs(key, value)
    file = fullfile(prefdir, "glab_dataman_prefs.mat");
    if ~exist(file, "file")
        prefs = struct();
    else
        prefs = load(file, "prefs");
    end
    prefs.(key) = value;
    save(file, "prefs");
end

