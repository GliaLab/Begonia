classdef VersionedData < handle
    %VERSIONEDDATA Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        tab
        
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
            %obj.index = struct();
            key = string.empty;
            data = cell.empty;
            version = [];
            changeflag = false(0);
            key_to_flag = cell.empty;    % what flags gets marked on write pr. key
            
            obj.tab = table(key, data, version, changeflag, key_to_flag);
            
            obj.next_index = 1;
            obj.lead_version = 1;
        end
        
        
        function idx = get_idx(obj, key)
            idx = find(obj.tab.key == key);
        end
        
        
        function [d, v] = read(obj, key, default)
            idx = obj.get_idx(key);
            
            if isempty(idx)
                if nargin < 3
                    error("Key does not exist and no default argument was given");
                end
                d = default;
                v = 0;
            else
                d = obj.tab.data{idx};
                v = obj.tab.version(idx);
            end
        end
        
        
        function v = write(obj, key, data)
            idx = obj.get_idx(key);
            new  = isempty(idx);
            
            obj.increment_v();
            v = obj.lead_version;
            
            if ~new
                obj.tab.key(idx) = key;
                obj.tab.data(idx) = {data};
                obj.tab.version(idx) = v;
            else
                data = {data};
                version = v;
                changeflag = true;
                key_to_flag = {string.empty};
                row = table(key, data, version, changeflag, key_to_flag);
                obj.tab = [obj.tab ; row];
            end

            % set all changeflags to true that are dependen on this key:
%             if isfield(obj.key_to_flag, key)
%                 dependent_flags = obj.key_to_flag.(key);
%                 for flag = dependent_flags
%                     obj.changeflag.(flag) = true;
%                 end
%             end
        end
        
        
        function has = has(obj, key)
            has = ~isempty(obj.get_idx(key));
        end
        
        
        % Assigns a flag to a key, meaning the flag will be set to positive
        % if any of the keys connected to it have changed.
        function assign_changeflag(obj, key, flag)
            % get existing flags, if any:
            existing = string.empty();
            if isfield(obj.key_to_flag, key)
                existing = obj.key_to_flag.(key);
            end
            
            % append flag, and ensure we're not with duplicates:
            flags = unique([existing flag]); %#ok<*PROPLC>
            obj.key_to_flag.(key) = flags;
            
            if ~isfield(obj.changeflag, flag)
                obj.changeflag.(flag) = true;
            end
        end
        
        
        function flagged = check(obj, flag, autostamp) 
            if nargin < 4
                autostamp = true;
            end

            flagged = obj.changeflag.(flag);
            if autostamp
                obj.stamp(flag);
            end
        end
        
        
        function stamp(obj, flag)
            obj.changeflag.(flag) = false;
        end
        
        
        function [has, write, read, check, stamp] = shorts(obj)
            has = @obj.has;
            write = @obj.write;
            read = @obj.read;
            check = @obj.check;
            stamp = @obj.stamp;
        end
        
    end
    
    methods (Access=private)

        function increment_v(obj)
            obj.lead_version = obj.lead_version + 1;
        end

    end
end

