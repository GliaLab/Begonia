classdef MultiTable < handle
    %MULTITABLE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        data
        base_table
        custom_columns
        custom_columns_default
    end
    
    methods
        
        function obj = MultiTable()
            entity = string.empty;
            category = string.empty;
            added = datetime.empty;
            source = begonia.data_management.multitable.Source.empty;
            
            obj.custom_columns = string.empty;
            obj.custom_columns_default = cell(0);
            
            obj.data = table(entity, category, added, source);
        end
        
        function register_column(obj, name, default)
            if ~isstring(name)
                error("Name must be string")
            end
            
            if contains(obj.custom_columns, name)
                return;
            end
            
            obj.custom_columns = [obj.custom_columns name];
            obj.custom_columns_default = [obj.custom_columns_default {default}];
        end
        
        function tab = get_extra_columns(obj, n)            
            tab = table();
            for i = 1:length(obj.custom_columns)
                col = obj.custom_columns(i);
                def = obj.custom_columns_default{i};
                tab.(col) = repmat(def, n, 1);
            end
        end
        
        function tab = get_empty_result_table(obj)
            
            entity = string.empty;
            category = string.empty;
            trace =  cell.empty;  %#ok<*PROPLC>
            trace_dt = [];
            
            seg_category = string.empty;
            seg_start_abs = datetime.empty;
            seg_start_f = [];
            seg_end_f = [];
            transition_f = [];

            tab = table(entity, category, trace, trace_dt, ...
                seg_category, seg_start_abs, seg_start_f, seg_end_f, ...
                transition_f);
            
            % final step: append extra columns:
            extras = obj.get_extra_columns(0);
            tab = horzcat(tab, extras);
        end
        
        function result = process_rows(rows)
            import begonia.util.to_loopable;
            
            result = table;
            
            % get rows with requested categories:
            rows = obj.data(contains([obj.data.category], categories),:);
            
            % run on_load on source, collect results:
            rows.source_rows = arrayfun(...
                @(src, ent, cat) src.on_load(obj, ent, cat) ...
                , rows.source, rows.entity, rows.category ...
                , "uniformoutput", false);
            
            % concatenate results:
            result = vertcat(rows.source_rows{:});
            result = sortrows(result, "entity");
        end
        
        
        function result = by_cat(obj, categories) 
            import begonia.util.to_loopable;
            
            result = table;
            
            % get rows with requested categories:
            rows = obj.data(contains([obj.data.category], categories),:);
            
            % run on_load on source, collect results:
            rows.source_rows = arrayfun(...
                @(src, ent, cat) src.on_load(obj, ent, cat) ...
                , rows.source, rows.entity, rows.category ...
                , "uniformoutput", false);
            
            % concatenate results:
            result = vertcat(rows.source_rows{:});
            if isempty(result)
                result = table();
                return
            end
            
            result = sortrows(result, "entity");
        end
        
        
        function result = by_entity(obj, entities) 
            rows = obj.data(contains([obj.data.entity], entities),:);
            rows.source_rows = arrayfun(...
                @(src, ent, cat) src.on_load(obj, ent, cat) ...
                , rows.source, rows.entity, rows.category ...
                , "uniformoutput", false);
            
            % concatenate results:
            result = vertcat(rows.source_rows{:});
            if isempty(result)
                result = table();
                return
            end
            
            result = sortrows(result, "entity");
        end
        

        % lists categories in the current table
        function cats = categories(obj)
            cats = unique(obj.data.category);
        end
    end
end

