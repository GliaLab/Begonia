classdef CaRoISource < begonia.data_management.multitable.Source
    %COMPARTMENTANALYSISSOURCE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        varname
        tseries
    end
    
    methods
        function obj = CaRoISource(tseries, varname)
            obj.tseries = tseries;
            obj.varname = varname;
        end
        
        function rows = on_load(obj, mtab, entity, category)
            signals = obj.tseries.load_var(obj.varname);
            roi_table = obj.tseries.load_var("roi_table");
            signals = join(signals, roi_table);
            
            tab_vars = signals.Properties.VariableNames;
            sigvar = string(tab_vars(startsWith(tab_vars, "signal")));
            
            trace = signals.(sigvar);
            roi_id = signals.roi_id;
            roi_type = signals.type;
            
            sz = size(trace);
            
            entity = repmat(entity, sz);
            category = repmat(category, sz);
            trace_dt = repmat(obj.tseries.dt, sz);
            
            seg_category = repmat("*", sz);
            seg_start_abs = repmat(obj.tseries.start_time, sz);
            seg_start_f = repmat(1, sz);
            seg_end_f = repmat(length(trace), sz);
            transition_f = repmat(missing, sz);
            
            trace = cellfun(@(t) t', trace, 'UniformOutput', false);

            rows = table(entity, category, trace, trace_dt, ...
                seg_category, seg_start_abs, seg_start_f, seg_end_f, ...
                transition_f);
            
            % append extra columns:
            extras = mtab.get_extra_columns(height(rows));
            extras.roi_id = roi_id;
            extras.roi_type = roi_type;
            
            rows = horzcat(rows, extras);
        end
        
        
        function on_load_complete(obj)
            
        end
        
    end
end

