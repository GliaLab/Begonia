function all_dirs = list_dirs(path,ignore_str)
% list_dirs lists all directories, recursively, of path.
%
%   all_dirs = list_dirs(path)
%   all_dirs = list_dirs(path,ignore_str)
%
%   REQUIRED
%   path        - (char) directory path.
%
%   OPTIONAL
%   ignore_str  - (char, default:'') directories containing ignore_str will
%                 not be entered, but the directories themselves will be listed
%                 in the output.
%
%   RETURNED
%   all_dirs    - (cell of char) array of paths. 
if nargin < 2
    ignore_str = '';
end
if isempty(path)
    path = '.';
end
if path(end) == filesep; path(end) = []; end

fast_failed = true;

if isunix
    if ~isempty(ignore_str)
        cmd = sprintf('find "%s" -type d -name ''*%s*'' -prune -print -o -type d -print',path,ignore_str);
    else
        cmd = sprintf('find "%s" -type d -print',path);
    end
    [~,out] = system(cmd);
    all_dirs = strsplit(out,'\n');
    
    % sometimes this fails, in which case it starts with 'find:'
    % fall back to alternative in this case:
    fast_failed = startsWith(out, 'find:') | startsWith(out, '/bin/');
end

if ~isunix || fast_failed
    all_dirs = strsplit(genpath(path),pathsep);
end

all_dirs = all_dirs(~cellfun('isempty',all_dirs));

end
