classdef VersionedData < handle
    %VERSIONEDDATA Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        index
        data
        version
        flagged
        
        lead_version
        next_index
    end
    
    methods
        function obj = VersionedData()
            % (1) For each key, we keep it's index in the arrays, it's data,
            % it's versions, it's flagged status. The entire object keeps a
            % lead version, which is the version all new writes are set to.
            % (2) For each index, we also keep a list of flags that it
            % invalidates on write
            obj.index = containers.Map();
            obj.data = cell.empty;
            obj.version = [];
            obj.next_index = 1;
            
            obj.lead_version = 1;
        end
        
        
        function [d, v] = read(obj, key, default)
            if ~obj.has(key)
                if nargin < 3
                    error("Key does not exist and no default argument was given");
                end
                d = default;
                v = 0;
            else
                idx = obj.index(key);
                d = obj.data{idx};
                v = obj.version(idx);
            end
        end
        
        
        function v = write(obj, key, data)
            obj.increment_v();
            
            if ~obj.has(key)
                idx = obj.next_index;
                obj.index(key) = idx;
                
                obj.next_index = obj.next_index + 1;
            else
                idx = obj.index(key);
            end

            obj.data{idx} = data;
            obj.version(idx) = obj.lead_version;
            v = obj.lead_version;
        end
        
        
        function has = has(obj, key)
            has = obj.index.isKey(key);
        end
        
        
        function [d, v] = is_flagged(key)
            
        end
        
        
        function [d, v] = flag_key_on(flag, id)
            
        end
        
        
        function shorts()

        end
        
    end
    
    methods (Access=private)
               
        
        function increment_v(obj)
            obj.lead_version = obj.lead_version + 1;
        end
        
        
        
    end
end

