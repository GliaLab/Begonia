classdef SuplimentaryEngine < begonia.data_management.DataLocationEngine
    %ONPATH Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Constant)
        datastore_name = 'metadata';
    end
    
    properties
        varmap
    end
    
    methods
        
        function obj = MapFileEngine(varmap)
            if nargin < 
            
        end
        
        
        function dpath = get_save_path(obj,dloc)
            dpath = fullfile(dloc.path, obj.datastore_name);
        end
        
        
        function save_var(obj, dloc, varname, data)
            vfile = fullfile(obj.get_save_path(dloc), ['var.', varname, '.mat']);
            begonia.path.make_dirs(vfile);
            save(vfile, 'data','-v7.3');
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

