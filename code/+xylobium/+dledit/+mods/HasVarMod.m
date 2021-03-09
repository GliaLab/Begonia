classdef HasVarMod < xylobium.dledit.model.Modifier
           
    properties
        replacement_value = true;
    end
        
    methods
        
        function obj = HasVarMod(key)
            obj = obj@xylobium.dledit.model.Modifier(key, false, true);
        end
        
        function value = onLoad(obj, dloc, ~, ~)
            value = dloc.has_var(obj.key);
        end
    end
end

