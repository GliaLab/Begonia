% A view holds a figure displaying ViewModules. Each view has it's own
% versioned data.
classdef View < handle
    
    properties
        manager
        modules
        figure
        zoomables
        
        data
        version
        valid
    end
    
    methods
        function obj = View(name, modules, manager)
            fig = figure("name", name, "position", [0 0 512 512]);
            fig.MenuBar = "none";
            fig.NumberTitle = "off";
            obj.figure = fig;

            obj.manager = manager;  % view manager 
            obj.modules = modules;  % view modules
            obj.zoomables % axis affected by zoom
            
            obj.data = roiman.VersionedData();
            obj.version = 1;
            
            pos = fig.Position;
            obj.data.write("window_dimensions", [pos(3) pos(4)]);
            
            fig.SizeChangedFcn = @(~, ev) obj.on_resize(ev);
        end
        
        
        function delete(obj)
            delete(obj.figure);
        end
        
        
        function is_valid = get.valid(obj) 
            is_valid = obj.version >= obj.data.lead_version;
        end
        
        
        function has_it = has_module(obj, identifier)
            has_it = any(contains([obj.modules.identifier], identifier));
        end
        
        
        % used by view modules to request an imagesc + axis
        function [hnd, ax] = request_imagesc(obj, w, h, zoomable) 
            ax = axes(obj.figure, "Position", [0 0 1 1]);
            hnd = imagesc(ax, 'CData', zeros(w, h));
            ax.YTick([]);
            ax.XTick([]);
            hold(ax, 'on')
            
            if zoomable
                obj.zoomables = [obj.zoomables ax];
            end
        end
        
        
        % used by view modules to request an axis
        function ax = request_ax(obj, w, h, zoomable) 
            ax = axes(obj.figure, "Position", [0 0 1 1]);
            ax.YLim = [0 h];
            ax.XLim = [0 w];
            ax.YTick([]);
            ax.XTick([]);
            ax.Box = 'off';
            ax.Color = 'none';
            hold(ax, 'on');
            
            if zoomable
                obj.zoomables = [obj.zoomables ax];
            end
        end
        
        
        % resizes the inner limits on figure resize
        function on_resize(obj, ev) 
            new_pos = obj.figure.Position;
            obj.data.write("window_dimensions", [new_pos(3) new_pos(4)]);
            obj.update_limits();
        end

        
        function on_mousemove(obj, event) 
            vp = obj.data.read("viewport");
            %dims = obj.manager.data.read("dimensions");
            wd = obj.data.read("window_dimensions");

            % x and y coordinate of the window:
            win_x = obj.figure.CurrentPoint(1);
            win_y = obj.figure.CurrentPoint(2);

            % convert to viewport coordinate
            x_ratio = vp(3) / wd(1);
            y_ratio = vp(4) / wd(2);
            vp_x = vp(1) + (win_x * x_ratio);
            vp_y = vp(2) + (win_y * y_ratio);
            
            % update the mouse structure:
            mouse = struct(); 
            mouse.viewport_x = round(vp_x); 
            mouse.viewport_y = round(vp_y);
            mouse.win_x = round(win_x); 
            mouse.win_y = round(win_y);

            obj.manager.data.write("mouse_pos", mouse);
        end


        function zoom(obj, factor)
            viewport = obj.data.read("viewport");
            mouse = obj.manager.data.read("mouse_pos");
            mouse_vp = [mouse.viewport_x, mouse.viewport_y];
            
            % calculate the new viewport based on the zoom factor:
            w = viewport(3) * factor;
            h = viewport(4) * factor;
            offset_x = mouse_vp(1) - w/2;
            offset_y = mouse_vp(2) - h/2;

            % make the new viewport
            vp = [offset_x, offset_y, w, h];
            obj.data.write("viewport", vp);

            obj.update_limits();
        end


        function zoom_reset(obj)
            dims = obj.manager.data.read("dimensions");
            obj.data.write("viewport", [0 0 dims]);
            obj.update_limits();
        end


        function center(obj)
            viewport = obj.data.read("viewport");
            mouse = obj.manager.data.read("mouse_pos");
            mouse_vp = [mouse.viewport_x, mouse.viewport_y];
            
            w = viewport(3);
            h = viewport(4);
            offset_x = mouse_vp(1) - w/2;
            offset_y = mouse_vp(2) - h/2;

            obj.data.write("viewport", [offset_x, offset_y, w, h]);
            
            obj.update_limits();
        end
        
        
        function update_limits(obj)
            viewport = obj.data.read("viewport");
            xl = [viewport(1), viewport(1) + viewport(3)];
            yl = [viewport(2), viewport(2) + viewport(4)];
            for ax = obj.zoomables
                xlim(ax, xl)
                ylim(ax, yl)
            end
        end
    end
end

