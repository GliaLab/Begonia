%{ 
Panel to see variable available in a model and change them. This panel will
fire and event when it edits the model, and the model will also fire
on_varlist_changed when this happens.  This allows unconnected objects to
register and react to these changes as well (such as DataGrid).
%}
classdef VariablePicker < handle
    
    properties
        selected_vars
        selected_vars_marked
        selected_vars_editable
    end
    
    properties(Access=public)
        figure
        panel
        model
        table
        textbox
        button_apply
    end
    
    events
        on_vars_changed
        on_apply
    end
    
    methods
        
        function obj = VariablePicker(model, fig, pos)
            if nargin < 2
                fig = figure('Position', [100,100, 450, 500]);
                %fig.CloseRequestFcn = @obj.handleClose;
                
                fig.ToolBar = 'none';
                fig.MenuBar = 'none';
                fig.Name = 'Variable picker';
                fig.NumberTitle = 'off';
            end
            
            obj.model = model;
            obj.figure = fig;
            
            obj.setupGUI();
            obj.setupEvents();
            
            % load initial data:
            obj.textbox.String = model.varlist;
            obj.doTextToTable();
            
        end
        
        
        function setupGUI(obj)
            % main panel:
            obj.panel = uipanel('Title','Variables' ...
                , 'FontSize', 12 ...
                , 'BackgroundColor','white' ...
                , 'Position', [0 0 1 1] ...
                , 'Parent', obj.figure ...
                , 'Units', 'pixels');
            
            % table:
            obj.table = uitable(obj.panel, 'units', 'normalized');
            obj.table.Position = [0, 0.05, 0.5, 0.95];
            obj.table.ColumnName = {'Show', 'Editable', 'Name'};
            obj.table.ColumnEditable = [true, true ,false];
            obj.table.ColumnWidth = {50, 50, 100};
            obj.table.RowName = {};
            obj.table.Data = {true, 'path', true, 'name'};
            
            % text editor:
            obj.textbox = uicontrol(obj.panel, 'units', 'normalized' ...
                , 'Style','edit' ...
                , 'Parent', obj.panel ...
                , 'String', {"hi"} ...
                , 'Position',[0.5, 0.05, 0.5, 0.95] ...
                , 'Max', 2 ...
                , 'HorizontalAlignment', 'left' ...
                , 'FontSize', 14);
            
            % apply button
            obj.button_apply = uicontrol(obj.panel, 'units', 'normalized'...
                , 'Style', 'pushbutton' ...,
                , 'String', 'Apply'...
                , 'Position', [0, 0, 1, 0.05]);
            
        end
        
        
        function setupEvents(obj)
            obj.textbox.Callback = @(~, ~) obj.doTextToTable();
            obj.table.CellEditCallback = @(~, ~) obj.doTableToText();
            obj.button_apply.Callback = @(~,~) obj.handleApplyButton();
        end
        
        
        % when text is edited - update table
        function doTextToTable(obj)
            data = {};
            
            selected = obj.selected_vars';
            all_vars = obj.model.all_vars;
            unselected = all_vars(~ismember(all_vars, selected));
            
            for var = [selected unselected]
                checked = ismember(var, selected);
                data = vertcat(data, { checked, false,  var{:} });
            end
            
            obj.table.Data = data;
           % obj.table.Data(:,2) = obj.selected_vars_editable;
            notify(obj, 'on_vars_changed');
        end
        
        
        % when TABLE is edited - update text
        function doTableToText(obj)
            lines = {};
            for i = 1:size(obj.table.Data, 1)
                row = obj.table.Data(i,:);
                if row{1} == true
                    str = row{3};
                    if row{2}
                        str = ['!' str];
                    end
                    lines = [lines str];
                end
            end
            
            obj.textbox.String = lines;
            notify(obj, 'on_vars_changed');
        end
        
        
        function handleApplyButton(obj)
            obj.model.varlist = obj.selected_vars_marked;
            
            notify(obj, 'on_apply');
        end
        
        
        % use text as a base for what variables is selected
        function vars = get.selected_vars(obj)
            vars = {};
            lines = obj.textbox.String;
            for i = 1:length(lines)
                line = strtrim(lines{i});
                if startsWith(line, '!')
                    line = line(2:end);
                end
                if ~isempty(line)
                    vars = vertcat(vars, { line });
                end
            end
        end
        
        
        function vars = get.selected_vars_marked(obj)
            vars = {};
            lines = obj.textbox.String;
            for i = 1:length(lines)
                line = strtrim(lines{i});
                if ~isempty(line)
                    vars = vertcat(vars, { line });
                end
            end
        end
        
        
        function editable = get.selected_vars_editable(obj)
            lines = obj.textbox.String;
            editable = startsWith(lines, '!');
            editable = arrayfun(@(e) mat2cell(e,1), editable);
        end
    end
end

