classdef ReadStructMod < xylobium.dledit.model.Modifier
           
    properties
        struct_key
    end
        
    methods
        
        function obj = ReadStructMod(struct_key,key)
            obj = obj@xylobium.dledit.model.Modifier(key, false, true);
            obj.struct_key = struct_key;
        end
        
        function value = onLoad(obj, dloc, ~, ~)
            value = dloc.load_var(obj.key,[]);
            if ~isempty(value)
                value = value.(obj.struct_key);
                if isa(value,'string')
                    value = char(value);
                end
            end
        end
    end
end
