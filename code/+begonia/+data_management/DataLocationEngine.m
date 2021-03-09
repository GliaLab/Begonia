classdef (Abstract) DataLocationEngine < handle
    %DATALOCATIONENGINE Summary of this class goes here
    %   Detailed explanation goes here
    
    methods (Abstract)
        save_var(obj, dloc, varname, data)
        
        data = load_var(obj, dloc, varname)
        
        clear_var(obj, dloc, varname)
        
        val = has_var(obj, dloc, varname)
        
        get_save_path(obj, dloc);
        
        get_saved_vars(obj, dloc);
        
        get_uuid_file(obj, dloc);
        
        ensure_uuid_possible(obj, dloc);
    end
    
    methods
        
        function duplicate_saved_data(self, dlocs)
            % duplicate_saved_data duplicates saved variables from input
            % DataLocations with the spesific DataLocationEngine.
            % 
            %   this.duplicate_saved_data(dlocs)
            %
            %   REQUIRED
            %   dlocs       - (DataLocation array)
            %                   DataLocations which data should be saved
            %                   with the current DataLocationEngine.
            %
            %   Write new data to old dloc.  
            %       old.dl_storage_engine.duplicate_saved_data(new)
            global BEGONIA_VERBOSE;
            for dloc = dlocs
                if BEGONIA_VERBOSE >= 1
                    str = dloc.path;
                    while length(str) > 60
                        str = strsplit(str,filesep);
                        if length(str) < 2
                            str = path;
                            break
                        end
                        str = fullfile(str{2:end});
                    end
                    str = sprintf('Duplicating data from: %s\n',str);
                    begonia.util.logging.vlog(1,str);
                end
                vars = dloc.saved_vars;
                for i = 1:length(vars)
                    data = dloc.load_var(vars{i});
                    self.save_var(dloc,vars{i},data);
                end
            end
        end
    end
    
end

