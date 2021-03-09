% This class adds the ability to read and write data to file in a simple manner.

classdef DataLocation < handle & matlab.mixin.Heterogeneous
% DATALOCATION Enables writing and reading (meta)data in a directory in a
% structured manner.

    properties
        path
        
        saved_vars % (dynamic) available var keys
        
        dl_storage_engine;
        dl_readonly = false;
        dloc_metadata_dir
        
        adapter = false;    % separates man from the animals
    end
    
    events
        on_var_saved
        on_var_cleared
        on_clear_all_vars
    end
    
    properties(Constant)
        UUIDFILE_ = 'uuid.begonia';
    end
    
    properties(Transient = true)
        dl_unique_id;
        dl_changelog;
    end
    
    properties(Access = private, Transient = true)
        dl_changelog_cached = []; %cached changelog
    end
    
    methods
        function self = DataLocation(path, storage_engine, skip_pathcheck)
            if nargin < 3
                skip_pathcheck = false;
            end
            
            if ~skip_pathcheck && ~exist(path, 'file')
                error(['DataLocation: requested path does not exist: ' path]);
            end
            
            if path(end) == filesep
                path(end) = [];
            end
            
            self.path = path;
            
            if nargin < 2
                storage_engine = begonia.data_management.engine_from_path(path);
            end
            
            self.dl_storage_engine = storage_engine;
        end
        
        
        function open(self)
            begonia.util.open_path_externally(self.path)
        end
        
        
        function dl_ensure_has_uuid(obj)
            if isprop(obj, "uuid") & ~isempty(obj.uuid) 
                return; 
            end
            
            % create uuid if it does not exist:
            uuid_file = obj.dl_storage_engine.get_uuid_file(obj);
            if ~exist(uuid_file, 'file')
                uuid = begonia.util.make_uuid();
                obj.dl_unique_id = uuid;
            end
        end
        
        
        function uuid = get.dl_unique_id(obj)
            % read unique identity of this folder from disk, or
            % create it if it does not yet exst:
            
            % default to UUID of object, if it exists:
            if isprop(obj, "uuid") && ~isempty(obj.uuid)
                uuid = obj.uuid; return
            end
            
            obj.dl_ensure_has_uuid();
            uuid_file = obj.dl_storage_engine.get_uuid_file(obj);
            if exist(uuid_file, 'file')
                uuid = strtrim(fileread(uuid_file));
            else
                uuid = [];
            end
        end
        
        
        function set.dl_unique_id(obj, value)
            
            % some engines need to prepare to store the uuid, so we give a
            % notice up front:
            obj.dl_storage_engine.ensure_uuid_possible();
            
            uuid_file = obj.dl_storage_engine.get_uuid_file(obj);
            if exist(uuid_file,'file')
                delete(uuid_file)
            end
            fid = fopen(uuid_file, 'wt');
            fprintf(fid, value);
            fclose(fid);
        end
        
        
        function vars = get.saved_vars(obj)
            vars = obj.dl_storage_engine.get_saved_vars(obj);
        end
        
        
        function tab = saved_vars_as_table(obj, vars)
            if nargin < 2
                vars = '';
            end
            
            if isempty(vars)
                vars = obj.saved_vars;
            end
            
            % create stucts for each var from 
            data = struct;
            
            for i = 1:length(vars)
                varname = char(vars(i));
                data.(varname) = '';
                
                
                if ismember(varname, obj.saved_vars) 
                    vardata = obj.load_var(varname, []);   % meta variable?
                elseif isprop(obj, varname)
                    vardata = obj.(varname);    % object field?
                else
                    vardata = '';
                end
                
                data.(varname) = {vardata};
                 
            end
            
            tab = struct2table(data);
        end
        
        
        % copies all data from data location provided to this object
        function dl_overwrite_from(obj, source, overwrite)
            if nargin < 3
                overwrite = true;
            end
            
            for var = source.saved_vars
                var_ = char(var);
                
                if var_ == "dl_internal_changelog"
                    continue;
                end
                
                if contains(var_, obj.saved_vars) && ~overwrite
                    continue;
                end
                obj.save_var(var_, source.load_var(var_));
            end
        end
        
        % copies data from source, and only overwrites entries that are
        % newer on source than target
        function dl_update_from(obj, source)
            for var = source.saved_vars
                var_ = char(var);
                if var_ == "dl_internal_changelog"
                    continue;
                end
                
                if obj.has_var(var_) 
                    if source.dl_changelog(var_) > obj.dl_changelog(var_)
                        obj.save_var(var_, source.load_var(var_));
                    end
                else
                    obj.save_var(var_, source.load_var(var_));
                end
            end
        end
        
        % gets a changelog for current saved vars
        function changelog = get.dl_changelog(obj)
            
            % used cacehed if we have it:
            if ~isempty(obj.dl_changelog_cached)
                changelog = obj.dl_changelog_cached;
                return;
            end
            
            % check if we already have one saved
            if obj.has_var('dl_internal_changelog')
                changelog = obj.load_var('dl_internal_changelog');
                obj.dl_changelog_cached = changelog;
                return;
            end
            
            % if neither saved, nor cached, we make one:
            % (this happens for old datalocations, and news ones)
            changelog = containers.Map;
            vars = obj.saved_vars;
            for i = 1:length(vars)
                if vars{i} ~= "dl_internal_changelog"
                    changelog(vars{i}) = [];
                end
            end
            obj.save_var('dl_internal_changelog', changelog);
            obj.dl_changelog_cached = changelog;
        end
            
        % gets the directory where meta data is stored - if onpath engine
        function p = get.dloc_metadata_dir(obj)
            p = obj.dl_storage_engine.get_save_path(obj);
        end
        
        
        
    end
    
    methods (Sealed)
        
        function save_var(objs, variable, data)
            import begonia.util.to_loopable;
            
            % Saves a variable to the the metadata directory (defaults to
            % 'metadata').  It takes the variable name, creates a file var.NAME.mat
            % that the contains the matlab variable.
            if isstring(variable)
                variable = char(variable); % FIXME
            end
            
            for obj = to_loopable(objs)
                % ensure this data location has a valid ID:
                obj.dl_ensure_has_uuid();
                
                if nargin < 3
                    % Only one input supplied. 
                    if ~isempty(inputname(2))
                        % The input was one named variable, save the data
                        % of that variable with the same variable name. 
                        data = variable;
                        variable = inputname(2);
                    elseif ischar(variable)
                        % The input was a char, but without a variable
                        % name. Eg. save_var('asd')
                        % Find the value of a variable with that name in
                        % the calling function workspace.
                        try
                            data = evalin('caller', variable);
                        catch
                            % The evalin error information is a bit obscure as most
                            % users have no idea what it does. Usually it gets an 
                            % error because the variable does not exist. 
                            error(sprintf('Undefined variable ''%s''', variable));
                        end
                    else
                        error('Illegal input.');
                    end
                end
                
                obj.dl_storage_engine.save_var(obj, variable, data);
                
                if variable ~= "dl_internal_changelog"
                    obj.dl_changelog(variable) = datetime();
                    obj.save_var('dl_internal_changelog', obj.dl_changelog);
                end
            end
            
            % fire changed notification event:
            edata = begonia.data_management.VarChangedEvent(variable);
            notify(obj, 'on_var_saved', edata);
        end
        
        % Loads the variable with the provided key from the corresponding
        % file in the metadata directory.  See save_data.
        function data = load_var(objs, key, default)
            if isstring(key)
                key = char(key); % FIXME
            end
            
            if ~isa(key, 'char')
                error(['Data location key needs to be a char vector, ' ...
                    'but got a ' class(key)]);
            end
            
            % Return the data in a cell array if multiple objects.
            data = cell(1,length(objs));
            for i = 1:length(objs)
                obj = objs(i);
                
                try
                    val = obj.dl_storage_engine.load_var(obj, key);
                catch e
                    % If cannot load and we have default argument
                    if nargin == 3
                        val = default;
                    else
                        rethrow(e);
                    end
                end
                data{i} = val;
            end
            
            % If just one dloc variable is loaded, do not return a cell
            % array.
            if length(objs) <= 1
                data = data{1};
            end
            
            % If no left side assignment, return the variable directly
            % to the callers workspace. 
            if nargout == 0
                assignin('caller', key, data);
            end
        end
        
        
        function val = has_var(objs, variable_name)
            if isstring(variable_name)
                variable_name = char(variable_name); % FIXME 
            end
            
            if isa(variable_name, 'char')
                variable_name = char(variable_name);
            end
                
            val = false(size(objs));
            for i = 1:length(objs)
                obj = objs(i);
                val(i) = obj.dl_storage_engine.has_var(obj, variable_name);
            end
        end
        
        
        function clear_var(objs, variable, fire_event)
             if isstring(variable)
                variable = char(variable); % FIXME 
            end
            
            if nargin == 2
                fire_event = true;
            end
            
            for obj = objs
                obj.dl_storage_engine.clear_var(obj, variable);
            end
            
            % fire changed notification event:
            if fire_event
                edata = begonia.data_management.VarChangedEvent(variable);
                notify(obj, 'on_var_cleared', edata);
            end
        end
        
        
        function clear_all_vars(objs)
            for obj = objs
                vars = obj.saved_vars;
                for i = 1:length(vars)
                    obj.clear_var(vars{i});
                end
            end
            
            % fire event:
            notify(obj, 'on_clear_all_vars');
        end
        
    end
    
end

