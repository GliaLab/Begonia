

classdef DataGrid < handle
    %DATAGRID Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        model
        figure
        table
        selection
    end
    
    properties(Dependent)
        position
        enabled
    end
    
    events
        on_selected
    end
    
    methods
        function obj = DataGrid(model, fig, pos)
            if nargin < 2
                fig = figure();
                fig.ToolBar = 'none';
                pos = [0, 0, 1, 1];
            end
            
            obj.model = model;
            obj.figure = fig;
            %obj.position = pos;
            
            
            obj.table = uitable(fig);  
            %obj.table = uitable(fig, 'units', 'normalized');  
            obj.table.Position = pos;
            obj.table.CellSelectionCallback = @obj.handleCellSelection;
            obj.table.CellEditCallback = @obj.handleCellChange;
            
            % initially load all data:
            obj.reloadTable()
            
            % set up event handlers:
            addlistener(model, 'on_varlist_changed', @obj.handleVarlistChanged);
            addlistener(model, 'on_var_changed', @obj.handleVarChanged);
        end
        
        
        function set.position(obj, pos)
            obj.table.Position = pos;
        end
        
        function pos = get.position(obj)
            pos = obj.table.Position;
        end
      
        function set.enabled(obj, state)
            obj.table.Enable = state;
        end
        
        % Reloads the entire datatable from model
        function reloadTable(obj)
            
            tab = obj.model.getFullTable();
            cells = table2cell(tab);
            cells = cellfun(...
                @(c) obj.cellToUTableFormat(c) ...
                , cells ...
                , 'UniformOutput', false);
            
            obj.table.Data = cells;
            obj.table.ColumnName = tab.Properties.VariableNames;
            obj.table.ColumnEditable = obj.model.var_editable;
        end
        
        
        % Ensures the format of the given cell works in uitable:
        function result = cellToUTableFormat(~, cell)
            if isa(cell, 'cell')
                result = '(cell)';
            elseif isa(cell, 'logical') || isa(cell, 'double')  || isa(cell, 'char')
                if ~isempty(cell) && ~isequal(size(cell), [1,1]) && ~isa(cell, 'char')
                    result = [class(cell) ' x ' mat2str(size(cell))];
                else
                    result = cell;
                end
            elseif isa(cell, 'struct')
                result = '(struct)';
            
            else
                result = '(other)';
            end
        end
        
        
        % Handle: when variable list in model changes, we need to reload
        % the entire model (for simplicity)
        function handleVarlistChanged(obj, ~, ~)
            obj.reloadTable();
        end
        
        
        % Handle: when a variable changes,it needs to be reloaded in the
        % data grid.  We will avoid realoading the entire table as this
        % messes with the colums.
        function handleVarChanged(obj, ~, evdata)
            % update cell:
            dloc = evdata.data_location;
            varname = evdata.variable_name;
            [c,r] = obj.model.getDlocVarIndex(dloc, varname);
            if ~isempty(c) && ~isempty(r)
                obj.table.Data{c,r} = obj.cellToUTableFormat(obj.model.load(dloc, varname));
            end
        end
        
        
        function handleCellSelection(obj, ~, evdata)
            indicies = evdata.Indices(:,:);
            obj.model.selectByIndicies(indicies);
        end
        
        function handleCellChange(obj, ~, evdata)
            index = evdata.Indices(:,:);
            new_val = evdata.NewData;
            [var, dloc] = obj.model.varFromIndex(index);
            obj.model.save(dloc, char(var), new_val);
        end
            
        
    end
end


