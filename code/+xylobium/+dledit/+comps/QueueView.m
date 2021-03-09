classdef QueueView < handle
    %QUEUELIST Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        model
        actions
        figure
        panel
        
        table
        do_button
        clear_button
        dump_button
        rethrow_button
        
        selected_actions = xylobium.dledit.Action.empty;
    end
    
    properties(Dependent)
        position
        enabled
    end
    
    properties(Access = private)
       listener_queue_changed
       listener_job_done
    end
    
    methods
        function obj = QueueView(model, fig, pos)
            if nargin < 3
                fig = figure('Position', [100,100, 550, 500]);
                fig.ToolBar = 'none';
                fig.MenuBar = 'none';
                fig.Name = 'Queued actions';
                fig.NumberTitle = 'off';
                pos = [0, 0, 550, 500];
            end
            
            obj.model = model;
            obj.figure = fig;
            
            obj.setupGui(pos);
            obj.setupEvents();
            obj.reloadQueue();
            
        end
        
        function delete(obj)
            delete(obj.listener_queue_changed);
            delete(obj.listener_job_done);
            delete(obj.figure);
        end
        
        function show(obj,bring_to_front)
            if nargin < 2
                bring_to_front = false;
            end
            obj.figure.Visible = 'on';
            
            if bring_to_front
                figure(obj.figure);
            end
        end
        
        function hide(obj)
            obj.figure.Visible = 'off';
        end
        

        function setupGui(obj, pos)
            obj.panel = uipanel(obj.figure ...
                , 'Units', 'pixels' ...
                , 'Position', pos ...
                , 'BorderType', 'none' ...
                );
            
            % table:
            obj.table = uitable(obj.panel);
            obj.table.Position = [0, 35, pos(3)-1, pos(4) - 35 + 1];
            obj.table.ColumnName = {'#', 'Status' , 'Name', 'Start', 'Time'};
            obj.table.RowName = {};
            obj.table.ColumnWidth = { 20, 40, 300, 80, 80 };
            obj.table.CellSelectionCallback = @obj.handleTableSelect;
            
            % do buttons
            small = ceil((pos(3)/2)/3);
            
            obj.do_button = uicontrol(obj.panel ...
                , 'Style', 'pushbutton' ...
                , 'String', 'Do actions' ...
                , 'Position', [0, 0, pos(3)/2, 35] ...
                , 'HorizontalAlignment', 'Left' ...
                , 'Units', 'normalized');
            obj.do_button.Callback = @(~,~) obj.model.runQueue();
            
            obj.clear_button = uicontrol(obj.panel ...
                , 'Style', 'pushbutton' ...
                , 'String', 'Clear all' ...
                , 'Position', [pos(3)/2, 0, small, 35] ...
                , 'HorizontalAlignment', 'Left' ...
                , 'Units', 'normalized');
            obj.clear_button.Callback = @(~,~) obj.handleClearRequest();
            
            obj.dump_button = uicontrol(obj.panel ...
                , 'Style', 'pushbutton' ...
                , 'String', 'Dump' ...
                , 'Position', [pos(3)/2 + small, 0, small, 35] ...
                , 'HorizontalAlignment', 'Left' ...
                , 'Units', 'normalized');
            obj.dump_button.Callback = @(~,~) obj.handleDumpRequest();
            
            obj.rethrow_button = uicontrol(obj.panel ...
                , 'Style', 'pushbutton' ...
                , 'String', 'Rethrow' ...
                , 'Position', [pos(3)/2 + (2*small), 0, small, 35] ...
                , 'HorizontalAlignment', 'Left' ...
                , 'Units', 'normalized');
            obj.rethrow_button.Callback = @(~,~) obj.handleRethrowRequest();
            
            
            obj.table.Units = 'normalized';
            obj.panel.Units = 'normalized';
            
        end
        
        
        function setupEvents(obj)
            % hide instead of delete when closed:
            obj.figure.CloseRequestFcn = @(s, e) obj.hide();
            
            % update table when actions queue changed:
            obj.listener_queue_changed = addlistener(obj.model ...
                , 'on_action_queue_changed' ...
                , @(s,e) obj.reloadQueue());
            
            obj.listener_job_done = addlistener(obj.model ...
                , 'on_queue_job_done' ...
                , @(s,e) obj.reloadQueue());
            
            obj.listener_queue_changed = addlistener(obj.model ...
                , 'on_queue_execution_start' ...
                , @(s,e) obj.handleQueueStart());
            
            obj.listener_queue_changed = addlistener(obj.model ...
                , 'on_queue_execution_end' ...
                , @(s,e) obj.handleQueueEnd());
            
        end
  
        
        function set.enabled(obj, state)
            obj.do_button.Enable = state;
        end
        
        
        % loads data into table from model action list, and enabled or
        % disables action buttons:
        function reloadQueue(obj)
            data = {};
            i = 1;
            cnt = length(obj.model.action_queue);
            for action = fliplr(obj.model.action_queue)
                dt = action.end_time - action.start_time;
                data = vertcat(data ...
                    , {cnt - (i - 1) ...
                    , action.status ...
                    , char(action.title) ...
                    , datestr(action.start_time, 'HH:MM:SS') ...
                    , datestr(dt, 'HH:MM:SS.FFF')...
                    , });
                i = i + 1;
            end
            obj.table.Data = data;
            
            if ~isempty(obj.model.action_queue)
                %obj.do_button.Enable = 'on';
                obj.clear_button.Enable = 'on';
                obj.dump_button.Enable = 'on';
                obj.rethrow_button.Enable = 'on';
                
            else
               % obj.do_button.Enable = 'off';
                obj.clear_button.Enable = 'off';
                obj.dump_button.Enable = 'off';
                obj.rethrow_button.Enable = 'off';
            end
            
            drawnow();
        end
        
        function handleQueueStart(obj)
            obj.figure.Name = '*** EXECUTING ***';
            obj.enabled = 'off';
        end
        
        
        function handleQueueEnd(obj)
            obj.figure.Name = 'Queued actions';
            obj.enabled = 'on';
        end
        
        % ask user if they are sure they want to clear the list, then do it
        % (should do it anyway really, just to be evil)
        function handleClearRequest(obj)
            answer = questdlg('Are you sure you want to clear queue?');
            if strcmp(answer, 'Yes')
                 obj.model.clearQueue();
            end
        end
            
        
        function handleDumpRequest(obj)
            % get selected action:
            assignin('base','dumped_actions', obj.selected_actions)
            disp('Dumped to "dumped_actions" in base workspace');
            disp('(you may need to write that in command window for it to become visible)');
        end
        
        
        function handleRethrowRequest(obj)
            if length(obj.selected_actions) > 1
                warning('More than one action selected - only first will throw');
            end
            
            for action = obj.selected_actions
                if ~isempty(action.err)
                    rethrow(action.err);
                else
                    disp('Action has no error');
                end
            end
        end
        
        
        function handleTableSelect(obj, ~, evdata)
            rows = evdata.Indices(:,1);
            all_actions = fliplr(obj.model.action_queue);
            obj.selected_actions  = all_actions(rows);
            obj.selected_actions;
        end

    end
end


















% 
% 
%      .--.         /``'.
%     /wwww\ .---. |* *  \
%     |-=-=|/ ^ ^ `;--. *|
%     \wwww/\^ ^ ^/~~~~\.'       __
%      '--'  '----|    |       .'-=\
%           .'``\ \~~~~/ .-""-:=-=-=|
%          /   * | '--' /><><><\=-=/
%          |*   /   .-""-.<><></--'
%           '--'   /~*~*~*\---'
%                  \*~*~*~/
%                   '----'
%                               HAPPY EASTER

