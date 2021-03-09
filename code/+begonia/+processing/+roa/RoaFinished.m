classdef RoaFinished < xylobium.dledit.model.Modifier
           
    properties
        
    end
        
    methods
        function obj = RoaFinished()
            obj = obj@xylobium.dledit.model.Modifier('roa_finished');
        end
        
        function value = onLoad(obj, dloc, ~, ~)
            % This whole thing checks if pre-processing and processing
            % parameters match the parameters that was used to make final
            % results. 
            
            % Check if the pre-processing parameters match the
            % pre-processing parameters of the saved data. 
            roa_pre_param = dloc.load_var('roa_pre_param',nan);
            roa_pre_param_hidden = dloc.load_var('roa_pre_param_hidden',nan);
            value_1 = isequal(roa_pre_param,roa_pre_param_hidden);
            
            % Check if the processing parameters match the
            % processing parameters of the saved data. 
            roa_param = dloc.load_var('roa_param',nan);
            roa_param_hidden = dloc.load_var('roa_param_hidden',nan);
            value_2 = isequal(roa_param,roa_param_hidden);
            
            if value_1 && value_2
                % Check that processed parameters match the pre-processed
                % parameters. 
                f = fieldnames(roa_pre_param);
                for ch = 1:length(roa_pre_param)
                    for i = 1:length(f)
                        if roa_param(ch).(f{i}) ~= roa_pre_param(ch).(f{i})
                            value = false;
                            return;
                        end
                    end
                end
                value = true;
            else
                value = false;
            end
        end
        
        
    end
end

