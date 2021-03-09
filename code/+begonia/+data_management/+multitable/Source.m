classdef Source < handle & matlab.mixin.Heterogeneous
    %SOURCE Summary of this class goes here
    %   Detailed explanation goes here
    
    methods 
        function rows = on_load(obj) 
            error("on_load not overridden in decendant class!")
        end
        
        function on_load_complete(obj)
            error("on_load_complete not overridden in decendant class!")
        end
    end
end

