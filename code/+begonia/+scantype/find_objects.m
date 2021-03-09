function objs = find_objects(path,classes,avoid,ignore,print)
% Recursively try to initialize each of the classes on each file or directory 
% below path. 
%   path    - (char) 
%   classes - (cell of function handles)
%   avoid   - (cell of char) folders containing any of the elements in this
%             list is not entered, but the folder itself is checked. 
%   ignore  - (cell of char) files of folder containing any of the elements
%             in this list is ignored completely. 
%   print   - (logical, default true)

if nargin < 5
    print = true;
end

if path(end) == filesep
    path(end) = [];
end

root_idx = length(strsplit(path,filesep));

objs = recur(path,root_idx,classes,avoid,ignore,print);

end

function obj = recur(path,root_idx,classes,avoid,ignore,print)

obj = [];

% Check the current path.
for i = 1:length(classes)
    try
        obj = classes{i}(path);
        break;
    catch e
        continue;
    end
end

parts = strsplit(path,filesep);

if isempty(obj)
    obj_class = '';
else
    c = strsplit(class(obj),'.');
    obj_class = sprintf('(%s)',c{end});
end

if print
    begonia.logging.log(1,'%s %s',fullfile(parts{root_idx:end}),obj_class)
end

% Return if a object was initialized from this path. 
if ~isempty(obj)
    return;
end

can_enter = ~contains(parts{end},avoid) && ~isfile(path);

if can_enter
    sub = dir(path);
    
    I = cellfun(@(x)contains(x,ignore),{sub.name});
    sub(I) = [];
    
    for i = 1:length(sub)
        if isequal(sub(i).name,'.') || isequal(sub(i).name,'..')
            continue;
        end
        sub_path = [sub(i).folder,filesep,sub(i).name];
        o = recur(sub_path,root_idx,classes,avoid,ignore,print);
        obj = [obj,o];
    end
end
end