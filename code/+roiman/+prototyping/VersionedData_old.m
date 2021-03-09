% NOTE: tested with tables and container.Map here and found that their
% looup and set times were significantly worse than that of structs with
% properties. The drawback is that the fields must have variable names
% acceptable to Matlab as proeprty names, but it's a small price to pay for
% the speed increase an ease of inspection for the data when in flight.

classdef VersionedData < handle
    %VersionedDataCarrier holds key-value pairs with versions 
    %   Used to know when data is changed.
    
    events
        on_data_changed
    end
    
    properties
        version
    end
    
    properties(Access=private)
        data_values
        data_versions
        data_version_accessed
    end
    
    methods
        
        function obj = VersionedData()
            obj.version = 1;
            obj.data_values = struct();
            obj.data_versions = struct();
            obj.data_version_accessed = struct();
        end
        
        %% second map to help systems keep track of when they last accessed 
        % and responded to data:
        function obsolete = is_obsolete(obj, key, accessor, auto_stamp)
            if nargin < 4
                auto_stamp = true;
            end
            
            obsolete = true;
            if isfield(obj.data_version_accessed, accessor)
                v = obj.data_versions.(key);
                l = obj.data_version_accessed.(accessor);
                obsolete = v > l;
            end
            
            % if auto-stamp, check = changes status
            if auto_stamp && obsolete
               obj.stamp(accessor);
            end
        end
        
        function stamp(obj, accessor)
            % why no key here? we can assume this to be a synchronous
            % series of operations. Writes always push versions to that of
            % the object, so it will be the same :fingerscrossed:
            obj.data_version_accessed.(accessor) = obj.version;
        end
        
        
        %% sets a named data vraiable on this objects, and gives it a version
        % number
        function v = write(obj, key, value)
            if ~isstring(key)
               error("Key must be a string"); 
            end
            
            v = obj.version + 1;
            obj.version = v;
            obj.data_values.(key) = value;
            obj.data_versions.(key) = obj.version;
            
            notify(obj,'on_data_changed');
        end
        
        %% gets a named data variable and it's version
        function [value, version] = read(obj, key, default)
            if ~isfield(obj.data_values, key)
                if nargin > 2
                    value = default; 
                    version = 0;
                else
                    value = []; 
                    version = [];
                end
                return
            end
            
            value = obj.data_values.(key);
            version = obj.data_versions.(key);
        end
        
        %% Performs "delete()" on value if it exists. Must be a handle.
        function delete_on_inner(obj, key, error_on_empty)
            if nargin < 4
                error_on_empty = false;
            end
            
            if obj.has(key)
                h = obj.read(key);
                delete(h);
            else
                if error_on_empty
                    error("No data with key: " + key);
                end
            end
        end
        
        
        function found = has(obj, key)
            found = isfield(obj.data_values, key);
        end
        
        function [data, vers] = dump(obj) 
            data = obj.data_values;
            vers = obj.data_versions;
        end
        
        
        %% Shortcut functions to simplify code, or pass into functions
        function [has, write, read, obso, stamp] = shortcuts(obj)
            has = @obj.has;
            write = @obj.write;
            read = @obj.read;
            obso = @obj.is_obsolete;
            stamp = @obj.stamp;
        end
    end

end

