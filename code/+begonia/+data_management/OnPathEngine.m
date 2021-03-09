classdef OnPathEngine < begonia.data_management.DataLocationEngine
    %ONPATH Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Constant)
        datastore_name = 'metadata';
    end
    
    methods
        function uuid_file = get_uuid_file(obj, dloc)
            uuid_file = fullfile(dloc.path, begonia.data_management.DataLocation.UUIDFILE_);
        end
        
        function ensure_uuid_possible(obj, dloc)
            
        end
        
        function dpath = get_save_path(obj,dloc)
            dpath = fullfile(dloc.path, obj.datastore_name);
        end
        
        
        function save_var(obj, dloc, varname, data)
            vfile = fullfile(obj.get_save_path(dloc), ['var.', varname, '.mat']);
            begonia.path.make_dirs(vfile);
            if exist(vfile,'file')
                delete(vfile)
            end
            % Save the matfile in a deterministic output by editing the
            % matfile. If the data is too big it must be saved with version
            % 7.3 instead. If the data is saved with 7.3 the output cannot
            % be saved deterministicically (so far). 
            info = whos('data');
            if info.bytes < 2^31 - 1
                save(vfile, 'data','-v7');
                % The beginning of the file has a timestamp and operating
                % system ID. That information is overwrittern with zeros. 
                fileID = fopen(vfile,'r+');
                fseek(fileID,21,'bof');
                fwrite(fileID,zeros(1,54));
                fclose(fileID);
            else
                save(vfile, 'data','-v7.3');
            end
        end
        
        
        function data = load_var(obj, dloc, varname)
            % Get the path of the mat file. 
            vfile = fullfile(obj.get_save_path(dloc), ['var.', varname, '.mat']);
            if exist(vfile, 'file')
                % Load the mat file.
                tmp = load(vfile);
                data = tmp.data;
            else
                error(['begonia:data_location:missing_variable:',varname], ...
                    ['Variable "', varname ,'" not found.']);
            end
        end
        
        
        function vars = get_saved_vars(obj,dloc)
            vars = {};
            files_structs = dir(obj.get_save_path(dloc));
            for i = 1:length(files_structs)
                file = files_structs(i);
                if startsWith(file.name, 'var.') && endsWith(file.name, '.mat')
                    vars = {vars{:} , file.name(5:end-4)};
                end
            end  
        end
        
        
        function val = has_var(obj, dloc, varname)
            if ~isa(varname, 'char')
                varname = char(varname);
            end
            vfile = fullfile(obj.get_save_path(dloc), ['var.', varname, '.mat']);
            val = exist(vfile, 'file') == 2;
        end
        
        
        function clear_var(obj, dloc, varname)
            vfile = fullfile(obj.get_save_path(dloc), ['var.', varname, '.mat']);
            if exist(vfile, 'file')
                delete(vfile);
            end
        end
    end
    
end

