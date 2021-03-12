classdef DataLocationSource < begonia.data_management.multitable.Source
    %DATALOCATIONSOURCE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        dloc
        varname
        inner_varname % for timeseries collections
        datatype
        dt
        temp_data
    end
    
    methods
        function obj = DataLocationSource(dloc, varname, datatype, inner_varname)
            % create a new dloc that uses the same enigne as the old one:
            obj.dloc = dloc;
            obj.datatype = datatype;
            obj.varname = varname;
            obj.inner_varname = inner_varname;
            obj.temp_data = [];
        end
        
        function rows = on_load(obj, mtab, entity, category)
            
            if obj.datatype == "var"
                trace = obj.dloc.load_var(obj.varname);
                dt = obj.dt;
            elseif obj.datatype == "timeseries"
                val = obj.dloc.load_var(obj.varname);
                dt = (val.TimeInfo.end - val.TimeInfo.Start) / length(val.Data);
                trace = val.Data;
            elseif obj.datatype == "timeseriescollection"
                if isempty(obj.temp_data)
                    obj.temp_data = obj.dloc.load_var(obj.varname);
                end
                tscol = obj.temp_data;
                ts = tscol.(obj.inner_varname);
                trace = ts.Data;
                dt = (ts.TimeInfo.end - ts.TimeInfo.Start) / length(trace);
            else
                error("Unknown datatype propertye - string must be var, timerseries or timeseriescollection");
            end

            % generate result row:
            trace = {trace};
            seg_category = "*";
            seg_start_abs = obj.dloc.start_time;
            seg_start_f = 1;
            seg_end_f = length(trace{:});
            trace_dt = dt; %#ok<*PROPLC>
            transition_f = missing;

            rows = table(entity, category, trace, trace_dt, ...
                seg_category, seg_start_abs, seg_start_f, seg_end_f, ...
                transition_f);
            rows = horzcat(rows, mtab.get_extra_columns(height(rows)));
        end
        
        function on_load_complete(obj)
            obj.temp_data = [];
        end
    end
end

