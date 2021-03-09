function paths_out = replace_root_dir(paths,root_dir,new_root_dir)
% paths         - (Cell array) Paths.
% root_dir      - (char) Root directory. 
% new_root_dir  - (char) Directory to replace root_dir with. 
%
%   Returns
% paths_out     - Empty if not all paths starts with root_dir. 

if root_dir(end) == filesep
    root_dir(end) = [];
end
if new_root_dir(end) == filesep
    new_root_dir(end) = [];
end

for i = 1:length(paths)
    str = paths{i}(1:length(root_dir));
    if ~isequal(str,root_dir)
        paths_out = [];
        return;
    end
end

paths_out = strrep(paths,root_dir,new_root_dir);

end

