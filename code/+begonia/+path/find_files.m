function [files_full,files] = find_files(path, substring, recursive)
% find_files finds all files containing substring. 
% 
%   files = find_files(path,substring)
%   files = find_files(path,substring,recursive)
%               
%   path        - (char array) path to look for file.
%   substring   - (char array) string that the file must include. 
%   recursive   - (logical) true looks in folders of folders
%                 (default: true).
%   files       - (cell of char) paths of each file found. 
if nargin < 3
    recursive = true;
end
% Check if path is a file that contains the substring.
if isfile(path)
    [~,name,ext] = fileparts(path);
    file = [name,ext];
    if contains(file,substring)
        files_full = {path};
        files = {file};
        return;
    end
end

% All things in the dir. 
files = dir(path);
% Get only files and their names. 
files = {files(~[files.isdir]).name};
% Ignore all files that contain tilde '~'.
files(contains(files,'~')) = [];
% Select files which contain substring.
files = files(cellfun(@(c)~isempty(strfind(c, substring)), files));
% Append the full path.
files_full = cellfun(@(c)fullfile(path,c), files, 'uni', false);

if recursive
    sub_dirs = begonia.path.get_subfolders(path);
    for i = 1:length(sub_dirs)
        sub_dir = sub_dirs{i};
        [ff,f] = begonia.path.find_files(sub_dir, substring);
        files = [files, f];
        files_full = [files_full,ff];
    end
end
end

