%{ 
Actions panel takes a list of EditorActions and creates buttons for them.
When an action is chosen, the on_action_chosen event is fired carryin with
it and ActionButtonEvent with a .action propery that can be used to
retrieve the action.
%}

classdef ActionsPanel < handle
    
    properties
        model
        actions
        figure
        panel
        
        button_height = 25;
        button_margin = 7;
        
        group_height = 20;
        
        buttons = [];
    end
    
    properties(Dependent)
        position
        enabled
    end
    
    events
       on_action    
       on_queue
    end

    methods
        
        function obj = ActionsPanel(model, actions, fig, pos)
            if nargin < 3
                fig = figure('Position', [100,100, 250, 500]);
                %fig.CloseRequestFcn = @obj.handleClose;
                
                fig.ToolBar = 'none';
                fig.MenuBar = 'none';
                fig.Name = 'Actions';
                fig.NumberTitle = 'off';
                pos = [0, 0, 250, 500];
            end
            
            obj.model = model;
            obj.actions = actions;
            obj.figure = fig;
            
            obj.setupGui(pos);
        end
        
        
        function delete(obj)
            delete(obj.figure);
        end
        
        
        % Craetes buttons from the actions provided in the constructor
        function setupGui(obj, pos)
            import xylobium.dledit.util.annotate_action_title;
            
            obj.panel = uipanel(obj.figure ...
                , 'Units', 'pixels' ...
                , 'Position', pos ...
                , 'BorderType', 'none' ...
                );
            
            % position for buttons inside panel, starting from top:
            x = 0 + obj.button_margin;
            y = pos(4);
            w = pos(3) - obj.button_margin * 2;
            h = obj.button_height;
            
            % get the button groups, and render buttons for each group:
            button_actions = obj.actions([obj.actions.has_button]);
            groups = unique([button_actions.button_group], 'stable');
            
            for group = groups
                y = y - obj.group_height;
                pos = [x, y, w, 15];
                uicontrol(obj.panel ...
                    , "style", "text"...
                    , "string", group...
                    , "position", pos...
                    , "HorizontalAlignment", "Left"...
                    , "FontWeight", "bold"...
                    , 'Units', 'normalized');
            
                % render buttons in this group:
                group_actions = button_actions([button_actions.button_group] == group);
                
                for action = group_actions
                    % callback button:
                    y = y - (obj.button_height + obj.button_margin);
                    pos = [x, y, w, h];
                    title = annotate_action_title(action);
                    action.button = uicontrol(obj.panel ...
                        , 'Style', 'pushbutton' ...
                        , 'String', title ...
                        , 'Position', pos ...
                        , 'HorizontalAlignment', 'Left' ...
                        , 'Units', 'normalized');
                    action.button.Callback = ...
                        @(src, ev) obj.handleButtonClick(action);
                    obj.buttons = [obj.buttons action.button];
                    
                end
                
                y = y - 10;
            end
            
            
        end

        
        function set.position(obj, pos)
            obj.panel.Position = pos;
        end
        
        
        function pos = get.position(obj)
            pos = obj.panel.Position;
        end
        
        
        function set.enabled(obj, state)
            set(obj.buttons, 'Enable', state);
        end

        
        function handleButtonClick(obj, action)
            ev = xylobium.dledit.comps.ActionButtonEvent(action);
            if action.can_queue
                notify(obj, 'on_queue', ev);
            else
                notify(obj, 'on_action', ev);
            end
        end
        
        
        % Cleans up events on exit
        function handleClose(obj, ~, ~)
            delete(obj.figure);
        end
        
    end
end





