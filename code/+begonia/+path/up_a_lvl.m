function paths_parent = up_a_lvl(paths)

paths_parent = cellfun(@up,paths,'UniformOutput',false);

end

function path = up(path)
if path(1) == filesep
    beginning_file_sep = true;
else
    beginning_file_sep = false;
end

path = strsplit(path,filesep);
if length(path) < 2
    path = path{1};
else
    path = fullfile(path{1:end-1});
end

path = [path,filesep];

if beginning_file_sep
    path = [filesep,path];
end
end