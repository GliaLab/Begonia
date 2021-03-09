classdef OffPathEngine < begonia.data_management.OnPathEngine
    %ONPATH Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        datastore_path
    end
    
    methods
        function obj = OffPathEngine(store_path)
            obj.datastore_path = store_path;
        end
        
        
        function dpath = get_save_path(obj, dloc)
            dpath = fullfile(obj.datastore_path, dloc.dl_unique_id);
        end
    end
    
end

