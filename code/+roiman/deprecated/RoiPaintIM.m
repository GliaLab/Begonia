classdef RoiPaintIM < roiman.ViewInputManager

    properties
        drag_state;
    end
    
    methods
        
        function obj = RoiPaintIM()
            obj@roiman.ViewInputManager("RoI Painter", "paint rois");
            obj.drag_state = false;
        end
        
        
        function on_scrollwheel(obj, manager, view, event)
            px = event.VerticalScrollCount;
            roiman.modes.RoIPaint.set_brush(manager, px, "increment");
        end
        
        
        function on_mousedown(obj, manager, view, event)
            % click always stamps a roi:
            mouse = manager.data.read("mouse_pos");
            roiman.modes.RoIPaint.add_to_mask(manager, mouse.viewport_x, mouse.viewport_y);
            
            % start drag state:
            obj.drag_state = true;
        end
        
        
        function handled = on_mousemove(obj, manager, view, event)
            % continue drawing if we are in the draw state:
            if obj.drag_state
                mouse = manager.data.read("mouse_pos");
                roiman.modes.RoIPaint.add_to_mask(manager, mouse.viewport_x, mouse.viewport_y);
            end
            
            handled = true;
        end
        
        
        function on_mouseup(obj, manager, view, event)
            obj.drag_state = false;
        end

    end
end

