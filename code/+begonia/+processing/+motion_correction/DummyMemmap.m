classdef DummyMemmap < handle
    properties
        Y
    end
    
    methods
        function val = size(self,varname)
            val = size(self.Y);
        end
        
        function val = whos(self,varname)
            val = struct;
            val.class = 'single';
        end
    end
end

