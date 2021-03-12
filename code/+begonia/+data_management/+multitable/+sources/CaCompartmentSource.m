classdef CaCompartmentSource < begonia.data_management.multitable.Source
    %COMPARTMENTANALYSISSOURCE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        metric
        tseries
        temp_data
    end
    
    methods
        function obj = CaCompartmentSource(tseries, metric)
            obj.tseries = tseries;
            obj.metric = metric;
            obj.temp_data = [];
        end
        
        function rows = on_load(obj, mtab, entity, category)
            comps = obj.tseries.load_var("compartment_signal");
            
            trace = comps.(obj.metric);
            sz = size(trace);
            
            entity = repmat(entity, sz);
            category = repmat(category, sz);
            trace_dt = repmat(obj.tseries.dt, sz);
            
            seg_category = repmat("*", sz);
            seg_start_abs = repmat(obj.tseries.start_time, sz);
            seg_start_f = repmat(1, sz);
            seg_end_f = cellfun(@length, trace);
            transition_f = repmat(missing, sz);
            
            trace = cellfun(@(t) t', trace, 'UniformOutput', false);
            compartment = string(comps.compartment) + " CH" + comps.channel;

            rows = table(entity, category, trace, trace_dt, ...
                seg_category, seg_start_abs, seg_start_f, seg_end_f, ...
                transition_f);
            
            % append extra columns:
            extras = mtab.get_extra_columns(height(rows));
            extras.ca_compartment = compartment;
            extras.ca_compartment_area_px2 = comps.area_px2;
            rows = horzcat(rows, extras);
        end
        
        
        function on_load_complete(obj)
            obj.temp_data = [];
        end
        
    end
end

