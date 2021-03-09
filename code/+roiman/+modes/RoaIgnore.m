classdef RoaIgnore < roiman.Mode

    properties
        HELP_MSG = "Ignore regions by clicking and dragging";
        GUIDE_TEXT = "";
    
        drag_state
    end
    
    methods
        
        function obj = RoaIgnore()
            obj = obj@roiman.Mode("ROA:IGNORE", "ai");
            obj.drag_state = false;
        end
        
        
        function on_init(~, manager)
            % initial brush size:
            roiman.modes.RoaIgnore.set_brush(manager, 10, "set");
        end
        
        
        function on_activate(obj, manager)
            [~, m_write, ~] = manager.data.shorts();
            
            m_write("message", obj.HELP_MSG)
            m_write("guide_text", replace(obj.GUIDE_TEXT, "\n", newline))
            
            for view = manager.views
                view.figure.Pointer = 'crosshair';
            end
        end
        
        
        function on_deactivate(obj, manager)
            [~, m_write, m_read] = manager.data.shorts();
            
            if m_read("message") == obj.HELP_MSG
                m_write("message", "");
            end
            
            for view = manager.views
                view.figure.Pointer = 'arrow';
            end
        end
        
        
        function on_mouse(obj, type, manager, view, event)
            if type == "wheel"
                px = event.VerticalScrollCount;
                
                roiman.modes.RoaIgnore.set_brush(manager, px, "increment");
                
            elseif type == "down"
                % click always stamps a roi:
                mouse = manager.data.read("mouse_pos");
                roiman.modes.RoaIgnore.add_to_mask(manager,view, mouse.viewport_x, mouse.viewport_y);

                % start drag state:
                obj.drag_state = true;
                
            elseif type == "move" && obj.drag_state
                % continue drawing if we are in the draw state:
                mouse = manager.data.read("mouse_pos");
                roiman.modes.RoaIgnore.add_to_mask(manager,view, mouse.viewport_x, mouse.viewport_y);
   
            elseif type == "up"
                obj.drag_state = false;
                
            end
        end
        
    end
    
    
    methods (Static)
        
        function add_to_mask(manager,view, x, y)
            [~, m_write, m_read] = manager.data.shorts();
            [~, v_write, v_read] = view.data.shorts();
            
            chan = v_read("channel");
%             mask = m_read("roa_ignore_mask_ch"+chan);
            roa_param = m_read("roa_param");
            mask = roa_param(chan).roa_ignore_mask;
            
            
            pix_to_dunit = m_read("pix_to_dunit");
            dunit = m_read("dunit");
            operation = m_read("roa_ignore_operation");
            r = m_read("roa_ignore_brush_size");
            
            % Make with true values inside the radius. 
            [X,Y] = meshgrid(-r:r,-r:r);
            brush_mask = sqrt(X.*X + Y.*Y) < r;
            
            % Find the crop around the position.
            xs = x - r;
            xe = x + r;
            ys = y - r;
            ye = y + r;
            
            if xs < 1
                brush_mask(:,1:1-xs) = [];
                xs = 1;
            end
            if ys < 1
                brush_mask(1:1-ys,:) = [];
                ys = 1;
            end
            if xe > size(mask,2)
                brush_mask(:,end-(xe-size(mask,2))+1:end) = [];
                xe = size(mask,2);
            end
            if ye > size(mask,1)
                brush_mask(end-(ye-size(mask,1))+1:end,:) = [];
                ye = size(mask,1);
            end
            
            source = mask(ys:ye, xs:xe);
            if operation == "add"
                mask(ys:ye, xs:xe) = brush_mask | source;
            elseif operation == "subtract"
                mask(ys:ye, xs:xe) = source - (source & brush_mask);
            end
%             m_write("roa_ignore_mask_ch"+chan, mask);
            roa_param(chan).roa_ignore_mask = mask;
            m_write("roa_param",roa_param);
            
            % inform size marked:
            area_px2 = round(pix_to_dunit(sum(mask(:))), 1);
            m_write("message", area_px2 + " " + dunit + "2");
        end
        
        
        function set_brush(manager, px, action)
            
            if action == "increment"
                brush_px = manager.data.read("roa_ignore_brush_size");
                brush_px = px + brush_px;
            elseif action == "set"
                brush_px = px;
            end
            
            if brush_px < 1
                brush_px = 1;
            elseif brush_px > 100
                brush_px = 100;
            end

            manager.data.write("roa_ignore_brush_size", brush_px);
        end
        
    end
end

