classdef DataLocationAdapter < handle & matlab.mixin.Heterogeneous

    properties
        path
        
        saved_vars
        
        dl_unique_id_;
        dl_storage_engine;
        dl_readonly = false;
        dloc_metadata_dir
        
        adapter = true;   % separates man from the animals
    end
    
    properties(Dependent)
        dl_unique_id;
    end
   
    
    events
        on_var_saved
        on_var_cleared
        on_clear_all_vars
    end
    
    methods
        
        function val = get.dl_unique_id(obj)
            if isempty(obj.dl_unique_id_)
                obj.dl_unique_id_ = begonia.util.make_uuid();
            end
            val = obj.dl_unique_id_;
        end
        
        function set.dl_unique_id(obj, val)
            obj.dl_unique_id_ = val;
        end
            
        
        function dl_ensure_has_uuid(obj)
            if isempty(obj.dl_unique_id)
                obj.dl_unique_id = begonia.util.make_uuid();
            end
        end

        function vars = get.saved_vars(obj)
            skiplist = {'saved_vars', 'dl_unique_id' ...
                , 'dl_storage_engine', 'dl_readonly' ...
                , 'dloc_metadata_dir', 'adapter'};
            all_props = properties(obj)';
            vars = setdiff(all_props, skiplist); 
        end

        function save_var(obj, variable, data)
            % error if non-object property:
            if ~obj.has_var(variable)
                error(['Property "' variable '" does not exist on object. When using DataLocationAdapter, all properties must exist on object']);
            end
            
            obj.(variable) = data;
            notify(obj, 'on_var_saved')
        end

        function data = load_var(obj, key, ~)
            data = obj.(key);
        end

        function val = has_var(obj, variable_name)
            val = any(contains(obj.saved_vars, variable_name));
        end

        function clear_var(obj, variable, ~)
            obj.save_var(variable, []);
            notify(obj, 'on_var_cleared')
        end
        
        function clear_all_vars(~)
            error('Cannot use clear_all_vars() on adapted objects');
        end
    end
end

