classdef Modifier < handle & matlab.mixin.Heterogeneous
    %TRANSFORMER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        key
        override_save;
        skip_load;
    end
    
    methods
        function obj = Modifier(key, override_save, skip_load)
            if nargin < 3
                skip_load = false;
            end
            
            if nargin < 2
                override_save = false;
            end
            
            obj.key = key;
            obj.override_save = override_save;
            obj.skip_load = skip_load;
        end
        
        function value = onLoad(obj, dloc, value, model)
        	
        end
        
        function value = onSave(obj, dloc, value, model)
        	model.save(dloc, obj.key, value);
        end
        
        
%         function value = onLoad(obj, dloc, value, model)
%         	value = dloc.load_var(obj.key);
%         end
%         
%         function value = onSave(obj, dloc, value, model)
%         	dloc.save(obj.key, value);
%         end

    end
end

