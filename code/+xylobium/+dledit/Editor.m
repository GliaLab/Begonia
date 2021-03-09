% The DataLocation editor provides a mechanism to view a large set of
% datalocation objects such as TSeries and other data, view their
% properties, and perform actions on these objects.
classdef Editor < handle

    properties
        model
        actions
        figure
        
        datagrid
        def_actions_panel
        cust_actions_panel
        menu_builder
        
        jobview
        queueview
        
        varpicker
        
        prev_title
        
        clipboard_value = [];
        
        use_filter;
        filters
        filters_
        filter
        filter_editor
        filter_set_button
        filter_apply
        
        misc_config
    end
    
    properties(Dependent)
        enabled
    end

    methods 
        
        % Constructor
        function obj = Editor(dlocs, actions, initial_vars, modifiers, show_queue, use_filter)
            import xylobium.dledit.*;
            import xylobium.dledit.model.*;
            import xylobium.dledit.comps.*;
            
            % i hate you matlab. So much.
            if nargin < 6
                obj.use_filter = false;
            else
                obj.use_filter = use_filter;
                obj.filter = "true % NO FILTER";
            end
            
            if nargin < 5
                show_queue = true;
            end
            if nargin < 4
                modifiers = Modifier.empty;
            end
            if nargin < 3
                initial_vars = {'name','path'};
            end
            if nargin < 2
                actions = Action.empty;
            end
            if nargin < 1
                dlocs = begonia.data_management.DataLocation.empty;
            end
            
            obj.misc_config = struct;

            obj.actions = [actions getDefaultActions()];

            obj.model = EditorModel(dlocs);
            obj.model.modifiers = modifiers;
            obj.model.varlist = initial_vars;
            
            % open job queue:
            obj.jobview = QueueView(obj.model);

            % user interface and events:
            obj.setupGui();
            obj.setupEvents();
            
            obj.jobview.hide();
        end
        
        function add_dlocs(obj,dlocs)
            obj.model.dlocs = [obj.model.dlocs(:)', dlocs(:)'];
            obj.datagrid.reloadTable();
        end
        
        function set_misc_config(obj,var,data)
            obj.misc_config.(var) = data;
        end
        
        function data = get_misc_config(obj,var)
            if isfield(obj.misc_config,var)
                data = obj.misc_config.(var);
            else
                data = [];
            end
        end
        
        % Creates the user interface
        function setupGui(obj) 
            import xylobium.dledit.comps.*;
                        
            left_extra = 150;
            top_extra = 20;
            
            obj.figure = figure('Position', [200,200, 800, 500]); %#ok<CPROP>
            obj.figure.ToolBar = 'none';
            obj.figure.MenuBar = 'none';
            obj.figure.NumberTitle = 'off';
            obj.figure.Name = 'Data Manager';
            
            % FIXME: these should not be the generic filters:
            obj.filters = [...
                "true % NO FILTER" ...
                , "dloc.load_var('demo', false)"];

            if obj.use_filter
                obj.filter_set_button = uicontrol(obj.figure, "style", "popupmenu", ... 
                    "string", obj.filters, ...
                    "Position", [0, 480, 50, 21]);
                obj.filter_set_button.Callback = @obj.handleSetFilter;

                obj.filter_editor = uicontrol(obj.figure, "style", "edit", ...
                    "string", obj.filters(1), ...
                    "Position", [50, 480, 750, 21], ....
                    "HorizontalAlignment", "left");
                
                obj.filter_apply = uicontrol(obj.figure, "style", "pushbutton", ...
                    "string", "Apply filter", ...
                    "Position", [725, 480, 75, 21], ....
                    "HorizontalAlignment", "left");
                obj.filter_apply.Callback = @obj.handleApplyFilter;
            else
                top_extra = 0;
            end
            
            obj.datagrid = xylobium.dledit.comps.DataGrid(...
                obj.model, obj.figure , [0 ,0, 500 + left_extra, 500 - top_extra]);
            
            if ~isempty(obj.actions) 
                obj.cust_actions_panel = ActionsPanel(...
                    obj.model...
                    , obj.actions...
                    , obj.figure...
                    , [651, 0, 150, 500 - top_extra]);
                disp('No actions');
            end
            
            % delegate menu building and events to a separate component:
            obj.menu_builder = MenuBuilder(obj);
        end
        
        
        
        % Sets up the system of events that will take control once the
        % constructor has run:
        function setupEvents(obj) 
            % shortcuts for cleaner code:
            do_action = @(~,ev) obj.handleActionRequested(ev.action);
            do_queue = @(~,ev) obj.handleQueueRequested(ev.action);
            
           % general events:
            obj.figure.ResizeFcn = @obj.handleResize;
            %obj.figure.KeyPressFcn = @obj.handleKeyPress;
            obj.figure.CloseRequestFcn = @(src, cbd) obj.handleCloseRequest(src, cbd);

            % datagrid events:
            %obj.datagrid.table.KeyPressFcn = @obj.handleKeyPress;
            
            addlistener(obj.model, 'on_selection_changed'... 
                , @(~,~) obj.handleSelectionChange());
            
            addlistener(obj.model, 'on_queue_execution_start'... 
                , @(~,~) obj.handleQueueExecutionStart());
            
            addlistener(obj.model, 'on_queue_execution_end'... 
                , @(~,~) obj.handleQueueExecutionEnd());
            
            % action panel events:
%             addlistener(obj.def_actions_panel, 'on_action'... 
%                 , @(~,ev) obj.handleActionRequested(ev.action));
            
            if ~isempty(obj.cust_actions_panel)
                addlistener(obj.cust_actions_panel, 'on_action'... 
                    , @(~,ev) obj.handleActionRequested(ev.action));
            
%                 addlistener(obj.def_actions_panel, 'on_queue'... 
%                     , @(~,ev) obj.handleQueueRequested(ev.action));

                addlistener(obj.cust_actions_panel, 'on_queue'... 
                    , @(~,ev) obj.handleQueueRequested(ev.action));
            end

            % menu events:
            addlistener(obj.menu_builder, 'on_action', do_action);
            addlistener(obj.menu_builder, 'on_queue', do_queue);
        end

        
        function delete(obj)
            delete(obj.model);
        end
        
        function quit(obj) 
            
             try
                delete(obj.queueview.figure);
             catch
                % naughty... 
             end
             delete(obj.figure);
             delete(obj);
        end
        
        function handleSetFilter(obj, s, ev)
            idx = obj.filter_set_button.Value;
            obj.filter = obj.filter_set_button.String(idx);
        end
        
        function handleApplyFilter(obj, s, ev)
            filter = obj.filter;
            obj.model.filter_expression = filter; 
            obj.datagrid.reloadTable();
        end
        
        function set.filter(obj, path) 
            obj.filter_editor.String = path;
        end
        
        function path = get.filter(obj) 
            path = obj.filter_editor.String;
        end
        
        function set.filters(obj, filters)
            obj.filters_ = filters;
            obj.filter_set_button.String = filters;
            obj.filter_editor.String = filters(1);
        end
        
        
        function filters = get.filters(obj)
            filters = obj.filters_;
        end
        
        function handleCloseRequest(obj, src, callbackdata)
             obj.quit()
        end
        
        % called when the selection of dataloctions in datagrid has changed -
        % needs to update the title primarely
        function handleSelectionChange(obj)
            selected = obj.model.selected;
            count = length(selected);
            obj.figure.Name = [num2str(count) 'x ' class(selected)  ' selected' ];
        end
        
        
        % called when a user presses a button in the figure. 
%         function handleKeyPress(obj, sender, ev)
%             code = xylobium.shared.keyboard_event_to_str(ev);
%             
%             % pass this message to the actions panels:
%             if ~isempty(code)
%                 obj.def_actions_panel.handleShortcutCode(code);
%                 obj.cust_actions_panel.handleShortcutCode(code);
%             end
%         end
        
        
        % checks if an action supports single  or multiple datalocations,
        % then calls the execution command on them
        function handleActionRequested(obj, action)
            
            if isempty(obj.model.selected)
                if action.can_execute_without_dloc
                    obj.executeActionCallback(action, []);
                else 
                    msgbox('Need to select something first');
                end
                return;
            end
            
            if action.accept_multiple_dlocs
                % execute on all selected dloc:
                obj.executeActionCallback(action, obj.model.selected)
            else
                % execute once pr. selected dloc
                for dloc = obj.model.selected
                    obj.executeActionCallback(action, dloc)
                end
            end
            
            % reload the data grid if specifically requested by action:
            if action.reload_on_execute
                obj.datagrid.reloadTable();
            end
        end
        
        
        % executes a callback from an action on one or mroe datalocations
        function executeActionCallback(obj, action, dloc)
            % ensure we catch errors, but do not permanently disable the
            % user interface.  We'll capture errors and rethrow after
            % re-enabling user interface:
            obj.enabled = 'off';
            err = [];

            try
                action.click_callback(dloc, obj.model, obj);
            catch err
                disp('Error!');
            end

            % at this point, the object may be deleted if the action was
            % the quiet request, so we need to return:
            if ~isvalid(obj) || ~isvalid(obj.figure)
                return;
            end
            obj.enabled = 'on';
            
            % rethrow if needed:
            if ~isempty(err)
               rethrow(err);
            end
        end
        
        % called when an action is requested to be queued from one of the
        % action panels
        function handleQueueRequested(obj, action)
            import begonia.util.to_loopable;
            obj.jobview.show();
            
            for dloc = to_loopable(obj.model.selected)
                name = dloc.path;
                if isprop(dloc, 'name')
                    name = "'" + dloc.name + "'";
                end
                
                obj.model.enqueueAction(...
                    action.title + " " + name ...
                    , action.click_callback...
                    , dloc ...
                    , obj);
            end
            
        end
        
        % Changes the state of the user interface to enable or disable
        % buttons. Used to lock the interface during processing
        function set.enabled(obj, state)
            if strcmp(state, 'off')
                obj.prev_title = obj.figure.Name;
                obj.figure.Name = '*** WORKING *** WORKING *** WORKING *** WORKING ***';
            else
                obj.figure.Name = obj.prev_title;
            end
            
            obj.def_actions_panel.enabled = state;
            obj.cust_actions_panel.enabled = state;
            obj.datagrid.enabled = state;
            drawnow();
        end
        
        % creates a queue view figure
        function showQueue(obj)
            if ~isempty(obj.queueview)
                delete(obj.queueview)
            end
            obj.queueview = xylobium.dledit.comps.QueueView(obj.model);
        end
        
        
        function handleQueueExecutionStart(obj)
            obj.enabled = 'off';
        end
        
        function handleQueueExecutionEnd(obj)
            obj.enabled = 'on';
            obj.datagrid.reloadTable();
        end
        
        
        % called when the window change size, andresized the individual 
        % GUI elements to fit the new position
        function handleResize(obj, ~, ~)
            left_extra = 150;
            
            if obj.use_filter
                top_extra = 20;
            else
                top_extra = 0;
            end
            
            win = obj.figure.Position;
            grid_pos = ceil(ceil([0,0, win(3)-(300 - left_extra), win(4) - top_extra]));
            %defac_pos = ceil([win(3)-299 + left_extra, 0, 150, win(4)]);
            cusac_pos = ceil([win(3)-149,0, 150, win(4) - top_extra]);
            filter_pos = ceil([50, win(4)- top_extra, win(3) - 75, top_extra]);
            filter_button_pos = ceil([0, win(4)- top_extra, 50, top_extra]);
            filter_apply_pos = ceil([win(3) - 75, win(4)- top_extra, 75, top_extra]);
            
            obj.datagrid.position = grid_pos;
            %obj.def_actions_panel.position = defac_pos;
            obj.cust_actions_panel.position = cusac_pos;
            obj.filter_editor.Position = filter_pos;
            obj.filter_set_button.Position = filter_button_pos;
            obj.filter_apply.Position = filter_apply_pos;
        end
    end
end














