function make_dirs(path)
% make_dirs creates folders along a path.
%   Does not delete anything.
%
%   make_dirs(path)
%
%   path        - (char array) directory path. If path does not end with a
%                 fileseperator sign the last part of the path is assumed
%                 to be a file and ignored.

% Only get directories.
[d,~,~] = fileparts(path);
path = d;

if isempty(path) || exist(path,'dir')
    return
end

path_parts = strsplit(path,filesep);
path_parts = path_parts(~cellfun('isempty',path_parts));

if startsWith(path,filesep)
    path_sub = filesep;
else
    path_sub = "";
end

for i = 1:length(path_parts)
    path_sub = fullfile(path_sub,path_parts{i});
    if ~exist(path_sub,'dir')
        mkdir(path_sub);
    end
end



end

