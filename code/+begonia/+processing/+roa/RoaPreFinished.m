classdef RoaPreFinished < xylobium.dledit.model.Modifier
           
    properties
        
    end
        
    methods
        function obj = RoaPreFinished()
            obj = obj@xylobium.dledit.model.Modifier('roa_pre_finished');
        end
        
        function value = onLoad(obj, dloc, ~, ~)
            % Check if the pre-processing parameters match the
            % pre-processing parameters of the saved data. 
            roa_pre_param = dloc.load_var('roa_pre_param',nan);
            roa_pre_param_hidden = dloc.load_var('roa_pre_param_hidden',nan);
            value = isequal(roa_pre_param,roa_pre_param_hidden);
        end
        
        
    end
end

