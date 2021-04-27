function npath = remap_path_root(path, old_root, new_root)
    % if no file separators, we might move architecture and should swap:
    if ~contains(path, filesep)
        if filesep == "\"
            path = replace(path, "/", filesep);
            old_root = replace(old_root, "/", filesep);
        elseif filesep == "/"
            path = replace(path, "\", filesep);
            old_root = replace(old_root, "\", filesep);
        end
    end
    
    % remap the root:
    npath = replace(path, old_root, new_root);
    
    % ensure no double separators:
    dbl = [filesep filesep];
    npath = replace(npath, dbl, filesep);
end

