function objs = init_classes_from_paths(varargin)
% init_classes_from_paths
%   The classes must either be correctly initialized with the path or throw
%   an error with an identifier that starts with 'begonia:load' to
%   be correctly accepted or skipped.  Any other errors will be rethrown. 
%
%   objs = init_classes_from_paths(dirs_in,classes)
%   objs = init_classes_from_paths(...,NAME,VALUE)
%
%   REQUIRED
%   dirs_in             - (cell of chars) 
%                           Each directory to attempt to initialize a 
%                           class. Each directory
%                           will be ran with each class and
%                           the first one that does not fail will be
%                           returned.
%   classes             - (cell of class handles) 
%                           Each class in a cell array with @ in front.
%   
%   PARAMETERS
%   show_waitbar        - (logical) 
%                           Show a gui progress bar.
%
%   RETURNED
%   objs                - (array of classes) 
%                           Empty if not found. The classes must be
%                           able to be in the same array 
%                           (e.g. mixin_heterogenious).
p = inputParser;
p.addRequired('dirs_in',...
    @(x) validateattributes(x,{'cell'},{}));
p.addRequired('classes', ...
    @(x) validateattributes(x,{'cell','function_handle'},{'nonempty'}));
p.addParameter('show_waitbar',false, ...
    @(x) validateattributes(x,{'logical'},{}));
p.parse(varargin{:});
begonia.util.dump_inputParser_vars_to_caller_workspace(p);

if isa(classes,'function_handle')
    classes = {classes};
end

if show_waitbar
    h = waitbar(0,'Scanning ... ');
end

cnt = 1;
begonia.logging.backwrite();
for i = 1:length(dirs_in)
    begonia.logging.backwrite(1,'Scanning paths (%d/%d) : %s', ...
        i,length(dirs_in),dirs_in{i});
    
    if show_waitbar
        waitbar(i/length(dirs_in),h);
    end

    for j = 1:length(classes)
        try
            path = dirs_in{i};
            % WORKAROUND: skip some dirs that cause problems:
            if endsWith(path, ".BIN") || contains(path, '.Trashes')
                continue;
            end
            objs(cnt) = classes{j}(path);
            cnt = cnt + 1;
            break
        catch e
            if contains(e.identifier,'begonia:load')
                continue;
            else
                rethrow(e);
            end
        end
    end
end

if show_waitbar
    close(h)
end

if ~exist('objs','var')
    objs = [];
end

begonia.logging.log(1,sprintf('Found %d objects',length(objs)))

end

