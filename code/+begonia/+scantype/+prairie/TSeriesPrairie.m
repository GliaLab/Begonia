classdef TSeriesPrairie < begonia.scantype.TSeries ...
        & begonia.scantype.prairie.PrairieOutput
    
    methods
        function obj = TSeriesPrairie(path)
            obj@begonia.scantype.prairie.PrairieOutput(path);
            
            assert(isequal(obj.type,'TSeries'), ...
                'begonia:load:unsupported_type', ...
                'Type must be TSeries');
        end
        
        function mat = get_mat(self,channel,cycle)
            if nargin < 3
                cycle = 1;
            end
            files = self.files(cycle,channel,:); 
            mat = begonia.scantype.prairie.PrarieFrameProvider(files);
        end
        
    end
end

