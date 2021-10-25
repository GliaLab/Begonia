% View manager stores data shared by multiple View objects and handles with
% modules. The modules will typically store the central data on the
% manager, and details on their visualization in the views. 
classdef ViewManager < handle
    
    events
        on_frame_changed
    end
    
    properties
        app % the owning app
        views % lits of views currently open
        current_view % the topmost view
        tools % hashmap of editors and other tools
        modes % hashmap of modes for the views
        
        data 
        valid
        version % if < data.version, the view is invalid and needs redraw
        
        timer
        autoplay_timer
        autoplay

        ticker
        
        % data fields for tools:
        name
        current_frame
        frame_count
        frame_times
        
        inter_update_tic
        render_time
        
        % editing support:
        memento
    end
    
    methods
        
        function obj = ViewManager(dataset, app)
            obj.version = 1;
            
            % the app holds many view managers, one for each data (tseries
            % etc.):
            obj.app = app;

            % managers hold GUI objects and data:
            obj.views = roiman.View.empty();
            obj.current_view = roiman.View.empty();
            obj.tools = containers.Map();
            obj.data = roiman.VersionedData();
            
            % grab convenience shortcuts for read and write ops:
            [o_has, o_write, o_read, o_flagged] = obj.data.shorts(); %#ok<*ASGLU>
            
            obj.autoplay = false;
            obj.render_time = zeros(1, 50);
            obj.inter_update_tic = nan;
            
            % initial mode is idle, but we also want to always include mode
            % select (which is also a mode):
            obj.modes = containers.Map();
            obj.modes("IDLE") = roiman.modes.IdleMode();
            obj.modes("MODE-SELECT") = roiman.modes.ModeSelect();

            % be nice and friendly:
            o_write("message", "GliaLab Markup/Analysis tool v0.0.3-dev");
            o_write("guide_text", "Welcome");
            
            % set an initial mouse position struct. Input managers update
            % this if they want to capture mouse position:
            mouse = struct(); 
            mouse.viewport_x = nan; 
            mouse.viewport_y = nan;
            mouse.win_x = nan; 
            mouse.win_y = nan;
            o_write("mouse_pos", mouse);

            % determine data type, and load (only tseries for now):
            if isa(dataset, "begonia.scantype.TSeries")
                o_write("datatype", "timeseries");
                obj.load_tseries(dataset);
            end

            % ready memento for editor - this holds 25 undo and
            % redo-operations:
            obj.memento = roiman.Memento(25);
            
            % start in idle mode:
            obj.set_mode("IDLE");
            
            obj.data.increment_v(); 
        end
        
        
        function load_tseries(obj, tseries)
            [o_has, o_write, o_read] = obj.data.shorts();
            
            if isempty(tseries.dt) || isnan(tseries.dt)
                dt = 1;
            else
                dt = tseries.dt;
            end
            
            if isempty(tseries.dx) || isnan(tseries.dx)
                dx = 1;
            else
                dx = tseries.dx;
            end
            
            w = waitbar(0, "Opening TSeries-type data");
            
            % Note: see documentation for details on what variables can go
            % into the datasets. This system uses loose semantics, so it's
            % important to look in the docs and keep them updated:
            disp("Data is timeseries, loading stack..");
            
            o_write("tseries", tseries);
            o_write("dimensions", tseries.img_dim(:)');
            o_write("viewport", [0 0 tseries.img_dim(:)']); % no zoom initially
            o_write("zoom", 1.0);
            
            % stacks are recorded in pixels, but displayed in micrometers
            % (hardcoded for now). We have functions to convert between
            % these units:
            o_write("unit", "pixels");
            if isempty(tseries.dx) || isnan(tseries.dx)
                o_write("dunit", "pixels");
                o_write("pix_to_dunit", @(n) n);
                o_write("dunit_to_pix", @(n) n);
            else
                o_write("dunit","μm")
                o_write("pix_to_dunit", @(n) n * dx);
                o_write("dunit_to_pix", @(n) n / dx);
            end
            
            o_write("z_plane", 1);
            o_write("current_frame", 1);
            o_write("frames", [1:tseries.frame_count]);
            o_write("frame_time", [1:tseries.frame_count] * dt);
            o_write("fps_default", 1 / dt);
            
            % load channels:
            chans = 1:tseries.channels;
            o_write("channels", chans);
            o_write("channel_names", string(tseries.channel_names));
            for chan = chans
                waitbar((0.8 / tseries.channels) * chan ...
                    , w ...
                    , "Loading " + chan);
                disp("Pre-fetching matrix for channel " + chan + ": " + tseries.channel_names(chan));
                
                % channels:
                mat = tseries.get_mat(chan);
                o_write("matrix_ch_" + chan, mat);
                
                % reference images
                o_write("ref_img_avg_ch_" + chan,  tseries.load_var("img_avg_ch" + chan + "_cy1", []));
                o_write("ref_img_std_ch_" + chan,  tseries.load_var("img_std_ch" + chan + "_cy1", []));
                o_write("ref_img_max_ch_" + chan,  tseries.load_var("img_max_ch" + chan + "_cy1", []));
            end
            
            % initial frame settings:
            obj.name = tseries.name;
            obj.current_frame = 1;
            obj.frame_times = [1:tseries.frame_count] * dt;
            obj.frame_count = tseries.frame_count;
            
            delete(w);
        end
       
        
        function set_active_view(obj, view)
            if isempty(obj.current_view) || view ~= obj.current_view
                obj.current_view = view;
                ev.to = obj.current_view;
                notify(obj, "on_view_changed", ev);
            end
        end
        
        
        function delete(obj)
            for view = obj.views
                delete(view);
            end 
            
            disp("Views and tools closed - done");
        end
        
        
%         function position = get_saved_window_position(obj, name)
%             position = [];
%             prefsfile = fullfile(prefdir(1), ".glrm_prefs.mat");
%             if exist(prefsfile, 'file')
%                 prefs = load(prefsfile, "window_positions");
%                 pos = prefs.window_positions;
%                 
%                 if pos.isKey(name)
%                     position = pos(name);
%                 end
%             end
%         end
%         
%         function save_window_positions(obj)
%             % capture all view window positions:
%             window_positions = containers.Map();
%             
%             for view = obj.views
%                 window_positions(view.figure.Name) = view.figure.Position;
%             end
%             
%             for tool_name = obj.tools.keys
%                 tool = obj.tools(tool_name{:});
%                 if isvalid(tool)
%                     if isprop(tool,'RootFigure')
%                         window_positions(tool_name{:}) = tool.RootFigure.Position;
%                     elseif isprop(tool,'UIFigure')
%                         window_positions(tool_name{:}) = tool.UIFigure.Position;
%                     else
%                         error('Where is the root figure??')
%                     end
%                 end
%             end
%             
%             prefsfile = fullfile(prefdir(1), ".glrm_prefs.mat");
%             save(prefsfile, "window_positions");
%         end
        
        % True if the manager has a version that is at last as high as it's
        % data. When data is written to the .data property, the version of
        % that object increments, meaning modules and dependent tools need
        % to be alerted and update themselves. 
        function is_valid = get.valid(obj)
            is_valid = obj.version >= obj.data.lead_version;
        end
        
        
        
        function new_view(obj, name, modules)
            view = roiman.View(name, modules, obj);
            
            dims = obj.data.read("dimensions");
            view.data.write("viewport", [0 0 dims]);
            
            % keybaord/mouse eventes are always ruted to the input manager, then
            % back to the input manager if unhandled. This is to secure the
            % mode switch and abort functions, i.e.
            fig = view.figure;
            fig.WindowKeyPressFcn = @(~, e) obj.handle_keyboard('down', e);
            fig.WindowKeyReleaseFcn = @(~, e) obj.handle_keyboard('up', e);

            fig.WindowScrollWheelFcn = @(s, e) obj.handle_mouse("wheel", e);
            fig.WindowButtonDownFcn = @(s, e) obj.handle_mouse("down", e);
            fig.WindowButtonUpFcn = @(s, e) obj.handle_mouse("up", e);
            fig.WindowButtonMotionFcn = @(s, e) obj.handle_mouse("move", e);
            
            % deal with close requests:
            view.figure.CloseRequestFcn = @(~, e) obj.app.handle_view_close(view, obj);
            
            % tell modules we're ready to go:
            for mod = view.modules; mod.on_init(obj, view); end
            for mod = view.modules; mod.on_enable(obj, view); end
            
            % tag the view with view, view manager - helps detecting
            % fornmost view:
            tag = struct();
            tag.view = view;
            tag.view_manager = obj;
            fig.UserData = tag;
            
            obj.views = [obj.views view];
            obj.current_view = view;
            
            % get the next view position:
            pos = obj.app.get_next_view_pos();
            fig.Position(1) = pos(1);
            fig.Position(2) = pos(2) - fig.Position(4);
            
            % notify we've changed the view:
            obj.app.set_active_view_and_manager(view, obj);
        end
        
        
        function focus_top_view(obj)
            figure(obj.current_view.figure);
        end
       
        
        
        function add_mode(obj, modeobj) 
            id = modeobj.name;
            obj.modes(id) = modeobj;
            modeobj.on_init(obj);
        end
        
        
        function set_mode(obj, name)
            % dont do anything if we are already in requested mode:
            old_mode = obj.data.read("mode", []);
            if ~isempty(old_mode) && name == old_mode.name
                return;
            end
            
            % ask old mode to deactivate, then activate new one:
            new_mode = obj.modes(name);
            if ~isempty(old_mode)
                old_mode.on_deactivate(obj);
            end
            
            obj.data.write("mode", new_mode);
            
            % remove e
            
            % tell new mode to activate:
            new_mode.on_activate(obj);
        end
       
        
        function result = has_mode(obj, name)
            result = obj.modes.isKey(name);
        end
        
        
        function update(obj, ~)
            obj.update_views();
            obj.update_autoplay();
            
            % synchronized firing of data objets on_data_change events:
            % (theoretically optimizes speed and prevents event queue
            % overflows):
            obj.data.fire_pending_events();
            for view = obj.views
                view.data.fire_pending_events();
            end
        end
        
        
        % cycles through all views, and asks them to update:
        function update_views(obj) 
            % update objects:
            next_version = obj.data.lead_version;
            
            % if we are not valid, we update all views:
            if ~obj.valid

                for view = obj.views
                    view_next_v = view.data.lead_version;
                    for mod = view.modules 
                       mod.on_update(obj, view); 
                    end
                    view.version = view_next_v;
                end
                
                obj.version = next_version;     % update applied
            else
                for view = obj.views
                    if ~view.valid
                        view_next_v = view.data.lead_version;
                        for mod = view.modules 
                           mod.on_update(obj, view); 
                        end
                        view.version = view_next_v;
                    end
                end
            end
            
        end
        
        % goes to a frame:
        function goto(obj, frame)
            obj.data.write("current_frame", frame);
            obj.data.write("current_time", obj.frame_times(frame));
            obj.current_frame = frame;
            notify(obj, "on_frame_changed");
        end
        
        
        % starts automatic playback with a fiven frames pr. second:
        function autoplay_start(obj, fps)
            [~, o_write, ~, ~] = obj.data.shorts();
            obj.autoplay = true;
            obj.autoplay_set_fps(fps);
            obj.data.write("message", "AUTOPLAY, target " + fps + " fps");
        end
        
        function autoplay_end(obj)
            obj.autoplay = false;
            obj.data.write("message", "AUTOPLAY OFF");
        end
        
       
        
        % called whenever autoplay timer ticks:
        function update_autoplay(obj) 
            if ~obj.autoplay; return; end
            
            [o_has, o_write, o_read, o_flagged] = obj.data.shorts();

            
            % get time since last autoplay update:
            if ~isnan(obj.inter_update_tic)
                dt_s = toc(obj.inter_update_tic);
                obj.render_time = circshift(obj.render_time, -1);
                obj.render_time(end) = dt_s;
            end
            obj.inter_update_tic = tic;
            
            % calculate the frame to display at current playtime:
            % Playtime -> fps-time -> frame -> frame-time
            t_start = o_read("autoplay_start_time", datetime());
            ap_frame_times = o_read("autoplay_frame_time"); %#ok<*PROPLC>
            frames = obj.data.read("frames");
            
            % calculate current frame, and go to it:
            playtime = seconds(datetime() - t_start);
            [~, frame] = min(abs(ap_frame_times - playtime));
        
            if playtime > ap_frame_times(end)
                frame = 1;
                o_write("autoplay_start_time", datetime());
                o_write("message", "LOOPED TO START");
            end
            
            obj.goto(frame);
            
            % calculate the actual FPS being rendered:
            fps_actual = round(1/mean(obj.render_time));
            o_write("fps_achieved", fps_actual);
        end
        
       
        % changes the frames-pr-second of the automatic playback:
        function autoplay_set_fps(obj, fps)
            [o_has, o_write, o_read, o_flagged] = obj.data.shorts();
            
            dt = 1/fps;

            % generate the time sequence based on delta time
            frames = o_read("frames");
            autoplay_frame_time = frames * dt;
            o_write("autoplay_frame_time", autoplay_frame_time);
            
            % correct for new frame times by setting playhead to current
            % frame:
            obj.playhead_to_frame();
        end
        
        function playhead_to_frame(obj)
            [o_has, o_write, o_read, o_flagged] = obj.data.shorts();

            % this offsets the playhead since current frame is calculated
            % from the time autoplay started. We'll need to subtract the offset
            % between the frame times to the start time:
            if obj.autoplay
                autoplay_frame_time = o_read("autoplay_frame_time", obj.frame_times);
                frame = o_read("current_frame");
                time_s = autoplay_frame_time(frame);
                corrected_start = datetime() - seconds(time_s);
                o_write("autoplay_start_time", corrected_start);
            end
        end
        
        
        % recives all mouse events (type = wheel, up, down) from view.
        % Manager can intercept them here, and then pass them on to the
        % current mode. We dont currently do anything with the mouse event
        % here, but it supports the concept that events go from
        % manager->mode.
        function handle_mouse(obj, type, event)
            mode = obj.data.read("mode", []);
            if isempty(mode); return; end % in case events occur to early
            
            % calculations of mouse position is handled by the view:
            view = obj.current_view;
            if type == "move"
                view.on_mousemove(event);
            end
            
            mode.on_mouse(type, obj, view, event)
        end
        
        
        % handles keyboard and passes it on to mode if we dont want to do
        % anything with the current key combination:
        function handle_keyboard(obj, type, event) 
            [~, o_write, o_read] = obj.data.shorts();
            [~, v_write, ~] = obj.current_view.data.shorts();
            
            handled = false;
            combo = join([sort(event.Modifier), event.Key], '-');
            
            % we start by universal commands that work in all modes:
            if type == "up"
                if combo == "period"
                    obj.set_mode("MODE-SELECT"); handled = true;
                elseif combo == "escape"
                    obj.set_mode("IDLE"); handled = true;
                elseif combo == "x"
                    obj.current_view.zoom(1/2); handled = true;
                elseif combo == "z"
                    obj.current_view.zoom(2); handled = true;
                elseif combo == "c"
                    obj.current_view.center(); handled = true;
                elseif combo == "v"
                    obj.current_view.zoom_reset(); handled = true;
                end
                
                % channel switch on numeric + shift:
                chan = str2double(event.Key);
                if ~isnan(chan) && any(event.Modifier == "shift")
                    chans = o_read("channel_names");
                    if chan > length(chans) || chan == 0
                        o_write("message","No such channel: " + chan);
                    else
                        v_write("channel", chan);
                        o_write("message", "=> " + chans(chan));
                        handled = true;
                    end
                    
                end
            end
            
            % if still not handled, we pass to mode:
            if ~handled
                mode = obj.data.read("mode", []);
                view = obj.current_view;
                if isempty(mode); return; end % in case events occur to early
                mode.on_keyboard(type, obj, combo, event)
            end
        end
        
        

        
    end
end

