function dirs = get_subfolders(path)
% get_subfolders returns all directories of path.
%
%   dirs = get_subfolders(path)
%
%   path        - (char array) path of directory.
%   dirs        - (cell of char) array of paths. 
dirs = dir(path);
dirs = {dirs([dirs.isdir]).name};
dirs = dirs(~ismember(dirs,{'.','..'}));
dirs = cellfun(@(c)fullfile(path,c) , dirs, 'uni', false);

end

