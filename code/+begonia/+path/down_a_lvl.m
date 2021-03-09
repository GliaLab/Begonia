function folders_out = down_a_lvl(folders,levels)
% down_a_lvl returns all subfolders of each of the directories in folders.
%
%   sub_folders = down_a_lvl(folders)
%   sub_folders = down_a_lvl(folders,levels)
% 
%   REQUIRED
%   folders         - (char array) 
%                       path to directory.
%
%   OPTIONAL
%   levels          - (int) 
%                       Goes down additional levels (default = 1).
%
%   RETURNED
%   sub_folders     - (cell of char) 
%                       paths to each sub dir. 
if ischar(folders)
    folders = {folders};
end
if nargin < 2
    levels = 1;
end

folders_out = folders;

for lvl = 1:levels
    sub = {};
    for i = 1:length(folders_out)
        tmp = begonia.path.get_subfolders(folders_out{i});
        tmp = reshape(tmp,[],1);
        sub = cat(1,sub,tmp);
    end
    folders_out = sub;
end

% for i = 1:length(folders)
%     sub = begonia.path.get_subfolders(folders{i});
%     sub_folders = {sub_folders{:}, sub{:}};
% end

end


