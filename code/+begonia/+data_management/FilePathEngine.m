classdef FilePathEngine < begonia.data_management.OnPathEngine
    
    properties
        metadir
    end
    
    properties(Access= private)
        metadir_checked = false;
    end
    
    methods

        function obj = FilePathEngine(metadir)
            obj.metadir = metadir;
        end
        
        function uuid_file = get_uuid_file(obj, dloc)
            uuid_file = fullfile(obj.metadir, begonia.data_management.DataLocation.UUIDFILE_);
        end
        
        function ensure_uuid_possible(obj, dloc)
            obj.ensure_metadir_exists();
        end
        
        function dpath = get_save_path(obj, dloc)
            dpath = fullfile(obj.metadir, obj.datastore_name);
        end

    end
    
    methods(Access=private)
        
        function ensure_metadir_exists(obj)
            if ~obj.metadir_checked
                if ~exist(obj.metadir, 'dir')
                    mkdir(obj.metadir);
                end
                obj.metadir_checked = true;
            end
        end
        
    end
    
end

