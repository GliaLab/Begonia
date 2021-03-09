classdef RapidDialog < handle
    %HSTACK Summary of this class goes here
    %   Detailed explanation goes here
    events
        on_choice
    end
    
    properties
        figure
        root
        panel
        
        controls;
        labels;
        types;
        defaults;
        
        label_width = 100
        padding = 10;
        choicebar_height = 50;
        
        height
        width
        
        choices
    end
    
    properties(Transient)
        title
        choices_controls
    end
    
    methods
        function obj = RapidDialog(parent_fig)
            % for use in stand-alone mode:
            if nargin < 2
                obj.figure = figure();
                obj.figure.MenuBar = 'none';
                obj.figure.ToolBar = 'none';
                obj.figure.NumberTitle = 'off';
                obj.figure.Resize = 'off';
                obj.root = obj.figure;
            else 
                obj.figure = parent_fig;
                % TODO: create panel
                
            end
        end
        
        function close(obj)
            delete(obj.figure);
        end
        
        function set.title(obj, title)
            obj.root.Name = title;
        end
        
        function add(obj, label, ctrl, type, default)
            
            if nargin < 5
                default = [];
            end
            
            if nargin < 4
                type = "text";
            end
            
            obj.controls = [obj.controls ctrl];
            ctrl.Parent = obj.root;
            
            obj.types = [obj.types string(type)];
            obj.defaults = [obj.defaults string(default)];
            
            % create control for label:
            label_ctrl = uicontrol(...
                'Style', 'text' ...
                , 'Position', [0 0 obj.label_width 30] ...
                , 'String', label ...
                , 'HorizontalAlignment', 'left');
            
            obj.labels = [obj.labels label_ctrl];
            label_ctrl.Parent = obj.root;
            
            obj.rebuild();
        end
        
        % height of the panel is accumulated height of controls + padding
        function height = get.height(obj)
            if isempty(obj.controls)
                height = 100;
                return;
            end
            
            ctrl_heights = arrayfun(@(c) c.Position(4), obj.controls);
            height = sum(ctrl_heights) ...
                + ((length(ctrl_heights) + 1) * obj.padding) ...
                + obj.choicebar_height;
        end
        
        % width of panel is label width + padding + larges control width
        function width = get.width(obj)
            if isempty(obj.controls)
                width = 100;
                return;
            end
            
            ctrl_widths = arrayfun(@(c) c.Position(3), obj.controls);
            width = obj.label_width ...
                + max(ctrl_widths) ....
                + (3 * obj.padding);
        end
        
        
        function set.choices(obj, choices)
            import xylobium.shared.control_helper.*;
            
            for choice = obj.choices_controls
                delete(choice);
            end
            
            for choice = choices
                b = button(choice, @(s, e) obj.handle_choice(s));
                obj.choices_controls = [obj.choices_controls b];
            end
            
            obj.rebuild();
        end
        
        % loads values from source to the dialog
        function load_values(obj, source)
            import xylobium.shared.layout.*;
            
            labs = {obj.labels.String};
            
            for i = 1:length(obj.controls)
                ctrl = obj.controls(i);
                varname =  RapidDialog.label_to_varname(labs{i});
                
                % look for a varname on the source:
                if isprop(source, varname)
                    value = source.(varname);
                    RapidDialog.assign_value_to_control(ctrl, value, varname);
                else
                    warning([...
                        '(RapidDialog.load_values) property not on source: "' ...
                        varname '"']);
                end
                
            end
        end
        
        % saves alues from the dialog to the target object
        function save_values(obj, target)
            import xylobium.shared.layout.*;
            
            labs = {obj.labels.String};
            
            for i = 1:length(obj.controls)
                ctrl = obj.controls(i);
                varname = RapidDialog.label_to_varname(labs{i});
                
                % look for a varname on the source:
                if isprop(target, varname)
                    RapidDialog.assign_value_to_object(ctrl, varname, target);
                else
                    warning([...
                        '(RapidDialog.save_values) property not on source: "' ...
                        varname '"']);
                end
                
            end
        end

        
    end
    
    
    methods (Static)
                
        function varname = label_to_varname(title)
            varname = lower(title);
            varname = replace(varname, ' ', '_');
            varname = matlab.lang.makeValidName(varname);
        end
        
        % assigns a value to a control in a type compatible fashion.
        function assign_value_to_control(ctrl, var, varname)
            if isa(var, 'double')
                if ctrl.Style == "edit"
                    ctrl.String = num2str(var);
                end
            elseif isa(var, 'logical')
                if ctrl.Style == "checkbox" 
                    ctrl.Value = var;
                end
            else
                warning(['(RapidDialog) : ' varname]);
                warning('(RapidDialog) Could not assign value - only double and logical currenlty supported (but feel free to expand!)');
            end
        end
        
        % reads value from a control (depending of type) and assignes it in
        % a type compatible fashion to the target object.
        function assign_value_to_object(ctrl, varname, target)
            if class(target.(varname)) == "double"
               if ctrl.Style == "edit"
                   target.(varname) = str2num(ctrl.String);
               end
            elseif class(target.(varname)) == "logical"
                if ctrl.Style == "checkbox"
                   target.(varname) = logical(ctrl.Value);
               end
            else
                warning(['(RapidDialog) : ' varname]);
                warning('(RapidDialog) Could not assign value - only double and logical currenlty supported (but feel free to expand!)');
            end
                
                
        end
        
    end
    
    methods (Access = private)
        
 
        function handle_choice(obj, sender)
            evdata = xylobium.shared.layout.RapidDialogChoiceEventData();
            evdata.choice = sender.String;
            notify(obj, 'on_choice', evdata);
        end
        
        function rebuild(obj)
            
            if isempty(obj.controls)
                obj.root.Position = [100, 100, 100, 100];
                return;
            end
            
            obj.root.Position = [100, 100, obj.width, obj.height];
            
            % reposition controls and labels:
            for i = 1:length(obj.controls)
                
                label = obj.labels(i);
                ctrl = obj.controls(i);
                sum_heights = sum(arrayfun(@(c) c.Position(4) ...
                    , obj.controls(1:i)));
                
                % label:
                label_pos = [obj.padding ...
                    , obj.height - (obj.padding * i - 1) - sum_heights ...
                    , obj.label_width ... 
                    , ctrl.Position(4)];
                
                label.Position = label_pos;
                
                % controller:
                ctrl_pos = [(obj.padding * 2) + obj.label_width ...
                    , label_pos(2) ...
                    , ctrl.Position(3) ...
                    , ctrl.Position(4)];
                    
                ctrl.Position = ctrl_pos;
            end
            
            
            % choices:
            if ~isempty(obj.choices_controls)
                ctrl_width = floor((obj.width)/length(obj.choices_controls)) ...
                    - (length(obj.choices_controls)) * obj.padding;
                
                ctrl_height = obj.choicebar_height - (2 * obj.padding);

                for i = 1:length(obj.choices_controls)
                    ctrl = obj.choices_controls(i);
                    x = (obj.padding * i) + (ctrl_width * (i-1));
                    y = obj.padding;
                    ctrl.Position = [x, y, ctrl_width, ctrl_height];
                end
            end
        end
        
    end
end



















