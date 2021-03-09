classdef DateTimeMod < xylobium.dledit.model.Modifier
           
    properties
        format
    end
        
    methods
        
        function obj = DateTimeMod(key, format)
            obj = obj@xylobium.dledit.model.Modifier(key);
            obj.format = format;
        end
        
        function value = onLoad(obj, dloc, ~, model)
            try
                dt = model.load(dloc, obj.key, false);
                dt.Format = obj.format;
                value = char(dt);
            catch err
                value = '(Mod error)';
            end
        end
        
        
    end
end

