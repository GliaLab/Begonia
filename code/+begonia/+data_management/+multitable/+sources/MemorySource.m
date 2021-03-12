classdef MemorySource < begonia.data_management.multitable.Source
    %COMPARTMENTANALYSISSOURCE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        start_abs
        trace
        dt
    end
    
    methods
        function obj = MemorySource(trace, dt, start_abs)
            obj.trace = trace;
            if iscolumn(trace)
                trace = trace';
            end 

            obj.trace = trace;
            obj.dt = dt;
            obj.start_abs = start_abs;
        end
        
        function rows = on_load(obj, mtab, entity, category)
            
            trace = {obj.trace};  %#ok<*PROPLC>
            trace_dt = obj.dt;
            
            seg_category = "*";
            seg_start_abs = obj.start_abs
            seg_start_f = 1;
            seg_end_f = length(trace);
            transition_f = missing;

            rows = table(entity, category, trace, trace_dt, ...
                seg_category, seg_start_abs, seg_start_f, seg_end_f, ...
                transition_f);
            
            % final step: append extra columns:
            extras = mtab.get_extra_columns(height(rows));
            rows = horzcat(rows, extras);
        end
        
        
        function on_load_complete(obj)
            
        end
        
    end
end

