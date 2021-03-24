classdef App < handle
    %APP Summary of this class goes here
    %   Detailed explanation goes here
    
    events
       on_view_changed
    end
    
    properties
        % update this key to avoid collisions between versions of the
        % preferences file:
        PREFS_KEY = ".glialab_roiman_prefs_v1.1.1.mat";
        
        % number of views pr. row anc column
        VIEW_OFFSET_MAX = 5;    
        
        view_managers
        tools
        
        update_timer % updates views and detects front window changed
        
        current_vm % ViewManager of front window
        
        % positions to place new views in:
        view_offset
    end
    
    methods
        function obj = App()
            REFRESH_RATE = 1/60;
            
            obj.view_managers = roiman.ViewManager.empty;
            obj.tools = containers.Map();
            obj.current_vm = roiman.ViewManager.empty;
            
            obj.view_offset = [0 0 0];
            
            % ready the update ticker that triggers render operations, but
            % dont start it:
            obj.update_timer = timer("startdelay", 0.01 ...
                ,"busymode", "drop" ...
                , "executionmode", "fixedrate" ...
                , "period",  round(REFRESH_RATE, 3)...
                , "timerfcn", @(sender, ev) obj.handle_updates(ev) ...
            ); 
        end
        
        
        % opens a data object from begonia scantypes:
        function vm = open(obj, data)
            vm = roiman.ViewManager(data, obj);
            
            obj.view_managers = [obj.view_managers vm];
            obj.set_active_view_and_manager(roiman.View.empty, vm);
        end
        
        
        % ensures tools only have a single instance, so we dont get
        % multiple roi-management windows, channel setting windows etc.
        % They should rather react to events when views are changed, and
        % update their data:
        function add_tool(obj, name, class_ref)
            import xylobium.shared.read_prefs;
            import xylobium.shared.ensure_onscreen;
            
            % if tool exists, we open the existing one:
            if obj.tools.isKey(name)
                tool = obj.tools(name);
            else
                % instance the class:
                tool = class_ref(obj);
                obj.tools(name) = tool;
            end
            
            % restore tool position:
            tool_pos = read_prefs(obj.PREFS_KEY, "tool_positions", []);
            if ~isempty(tool_pos) && tool_pos.isKey(name)
                pos = tool_pos(name);
                pos = ensure_onscreen(pos);
                tool.RootFigure.Position(1) = pos(1);
                tool.RootFigure.Position(2) = pos(2);
            end
        end
        
        function open_tool(obj, name)
            % if tool exists, we open the existing one:
            if obj.tools.isKey(name)
                tool = obj.tools(name);
                figure(tool.RootFigure);
            else
                warning("No such tool");
            end
        end
        
        
        % sets the current view:
        function set_active_view_and_manager(obj, view, vm)
            
            if nargin < 3
                vm = view.manager;
            end
            
            % set current view as active:
            if ~isempty(view)
                if view.manager ~= vm
                    error("Trying to set a view as current on a view "...
                        + "manager that is not it's owner");
                end
                vm.current_view = view;
                figure(view.figure);
            end
            
            % noitfy we've changed, allowing tools to handle the change:
            ev = roiman.ViewChangeEventData();
            if ~isempty(obj.current_vm) && isvalid(obj.current_vm)
                ev.from = obj.current_vm.current_view;
            else
                ev.from = roiman.View.empty;
            end
            ev.to = view;
            ev.viewmanager = vm;
            ev.viewmanager_changed = vm ~= obj.current_vm;
%             if ev.viewmanager_changed
%                 disp("Viewmanager changed");
%             end
            
            obj.current_vm = vm;
            
            notify(obj, "on_view_changed", ev);
        end
        
     
        % runs the program after setup
        function run(obj)
            disp("Program starting")
            start(obj.update_timer);
        end
       
        
        % debug version of the core loop - this one will lock matlab, but precents
        % timers from obfuscating errors
        function run_debug(obj)
            while isvalid(obj)
                tic;
                obj.handle_updates()
                td = toc;
                pause((1/30) - td);
            end 
        end

        
        % quittingthe all means deleting all view managers and tools
        function quit(obj)
            import xylobium.shared.write_prefs;
            
            stop(obj.update_timer);
            
            % save tool positions:
            tool_pos = containers.Map();
            for name = obj.tools.keys
                tool = obj.tools(name{:});
                if ~isvalid(tool)
                    continue;
                end
                fig = tool.RootFigure;
                pos = [fig.Position(1) fig.Position(2)];
                tool_pos(name{:}) = pos;
            end
            write_prefs(obj.PREFS_KEY, "tool_positions", tool_pos);
            
            % close all view managers:
            for vm = obj.view_managers
                delete(vm);
            end
            obj.view_managers = [];
            
            % close all tools:
            for name = obj.tools.keys
                tool = obj.tools(name{:});
                delete(tool);
                obj.tools.remove(name{:});
            end
            
            delete(obj);
        end
        
        
                
        function handle_view_close(obj, view, vm)
            % are we closing the final view?
            if length(vm.views) == 1
                % remove view manager:
                obj.view_managers = obj.view_managers(obj.view_managers ~= vm);
                delete(vm); % brutal!
                if ~isempty(obj.view_managers)
                    nvm = obj.view_managers(end);
                    obj.set_active_view_and_manager(nvm.views(end), nvm);
                else
                    obj.set_active_view_and_manager(roiman.View.empty, roiman.ViewManager.empty);
                end
            else
                % if not, we remove the view, but not the vm:
                vm.views = vm.views(vm.views ~= view);
                obj.set_active_view_and_manager(vm.views(end), vm);
            end
            
            
        end
        
        
        % handles the update timer: 
        function handle_updates(obj, ~)
            % each view managers are respoisble for updating themselves:
            for vm = obj.view_managers
                if isvalid(vm) 
                    vm.update()
                end
            end
            
            % has the current front view changed due to events?
            obj.detect_top_window_changed();
        end
        
        
        % runs on timer to check if the current topmost view is different
        % from the previous. 
        function detect_top_window_changed(obj)
            % there appears to be no events of callbacks in matlab that
            % detects changes to the frontmost window. Since we already
            % have a critical update loop, we can poll the status of the
            % frontmost window instead.
            % NOTE: this works because uifigures are not caught by gcf or
            % the groot -> CurrentFigure.
%             h =  findobj('type','figure');
%             n = length(h);
%             if n < 1; return; end
            
            % get the view and view manager of current figure, and ignore
            % the whole thing if it's not "one of ours":
            fig = get(groot,'CurrentFigure');
            if isempty(fig); return; end
            if ~isstruct(fig.UserData) || isempty(fig.UserData); return; end

            vm = fig.UserData.view_manager;
            view = fig.UserData.view;
            if view == obj.current_vm.current_view
                return;
            end
            
            disp("VM changed")
            obj.set_active_view_and_manager(view, vm);
        end
        
        % Moves all windows to the top
        function raise_all_windows(obj) 
            for vm = obj.view_managers
                for view = vm.views
                    figure(view.figure);
                end
            end
            
            for key = obj.tools.keys()
                tool = obj.tools(key{:});
                if isvalid(tool) && tool.RootFigure.Visible == "on"
                    figure(tool.RootFigure);
                end
            end
        end     
        
        
        function pos = get_next_view_pos(obj)
            screen = get(0, 'screensize');
            top = screen(4);
            
            cnt = obj.view_offset(1);
            step = obj.view_offset(2);
            
            pos = [100 + (50 * cnt) + (step * 200) ...
                top - (100 + (50 * cnt))];
                
            if cnt >= obj.VIEW_OFFSET_MAX
                cnt = 0;
                step = step + 1;
            else
                cnt = cnt + 1;
            end
                
            obj.view_offset = [cnt step];
        end
        
    end
    
    
end

