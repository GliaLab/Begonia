classdef ParamMod < xylobium.dledit.model.Modifier
           
    properties
        
    end
        
    methods
        function obj = ParamMod(key)
            obj = obj@xylobium.dledit.model.Modifier(key);
        end
        
        function value = onLoad(obj, dloc, ~, ~)
            value = dloc.load_var(obj.key,[]);
            if ~isempty(value)
                value = struct2table(value,'AsArray',true);
            end
        end
    end
end

