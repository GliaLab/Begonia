% Versioned data functions like a map/hashmap/dict and stores named
% key-value pairs. In addition it keeps version numbers of data written, so
% that changes can be easily flagged and tracked by modules and modes that
% use them. The system is tuned towrads read/flagcheck speeds, as these
% outnumber writes. Matlab struct properties were found to be much faster
% than container.Map and tables when testing. In Protoyping, discarded
% versions of the versioned data class can be found.

% On write, the key's version if set to the lead_version, and the lead
% version incremented. 
%
% FIXME: is there a theoretical possibility the lead version could wrap
% around? Probably an extreme edge case.
classdef VersionedData < handle

    events
        on_data_changed
    end
    
    properties
        index
        data
        version
        changeflag
        key_to_flag
        
        lead_version
        next_index
        
        datachange_ev_pending
    end
    
    methods
        function obj = VersionedData()
            obj.data = struct();
            obj.version = struct();
            obj.changeflag = struct();
            obj.key_to_flag = struct();    % what flags gets marked on write pr. key
            
            obj.next_index = 1;
            obj.lead_version = 1;
            
            obj.datachange_ev_pending = false;
        end
        
        
        function [d, v] = read(obj, key, default)
            if ~obj.has(key)
                if nargin < 3
                    error("Key does not exist and no default argument was given ");
                end
                d = default;
                v = 0;
            else
                d = obj.data.(key);
                v = obj.version.(key);
            end
        end
        
        
        function v = write(obj, key, data, fire_event)
            if nargin < 4
                fire_event = true;
            end

            obj.increment_v();
            
            obj.data.(key) = data;
            obj.version.(key) = obj.lead_version;
            v = obj.lead_version;
            
            % set all changeflags to true that are dependen on this key:
            if isfield(obj.key_to_flag, key)
                dependent_flags = obj.key_to_flag.(key);
                for flag = dependent_flags
                    obj.changeflag.(flag) = true;
                end
            end
            
            if fire_event
                obj.datachange_ev_pending = true;
            end
        end
        
        
        function has = has(obj, key)
            has = isfield(obj.data, key);
        end
        
        
        % Assigns a flag to a key, meaning the flag will be set to positive
        % if any of the keys connected to it have changed.
        function assign_changeflag(obj, keys, flag)
            for key = keys
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
        end
        
        % returns true if the names flag indicates a dependent key has been
        % written since *last check*. Settings autostamp to false will not
        % reset the flag.
        function flagged = check(obj, flag, autostamp) 
            if nargin < 4
                autostamp = true;
            end
                
            if ~isfield(obj.changeflag, flag)
                flagged = false;
                return
            end
            
            flagged = obj.changeflag.(flag);
            if autostamp
                obj.stamp(flag);
            end
        end
        
        
        function stamp(obj, flag)
            obj.changeflag.(flag) = false;
        end
        
        % Creates shortcuts for r/w and flag operations on the current
        % object. Allows a neater API in objercts that read and write the
        % data. 
        function [has, write, read, check, stamp] = shorts(obj)
            has = @obj.has;
            write = @obj.write;
            read = @obj.read;
            check = @obj.check;
            stamp = @obj.stamp;
        end
        
        function increment_v(obj)
            obj.lead_version = obj.lead_version + 1;
        end
        
        
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
        
        
        function fire_pending_events(obj)
            if obj.datachange_ev_pending 
                notify(obj,'on_data_changed');
                obj.datachange_ev_pending = false;
            end
        end
        
    end
end

