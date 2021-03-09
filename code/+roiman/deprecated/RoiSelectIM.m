classdef RoiSelectIM < roiman.ViewInputManager
    %ROISELECTIM Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        drag_state
        drag_points
        shift_down
    end
    
    methods
                
        function obj = RoiSelectIM()
            obj@roiman.ViewInputManager("RoI Select", "select rois");
            obj.drag_state = false;
        end
        
        
        function on_scrollwheel(obj, manager, view, event)
            
        end
        
        
        function on_mousedown(obj, manager, view, event)
            [~, m_write, m_read] = manager.data.shorts();
            [~, ~, v_read] = view.data.shorts();
            
            % get roi at coordinate:
            roi_table = m_read('roi_table');
            chan = v_read('channel');
            
            % matlab is quierky and renders some things bottom up, so we
            % need to flip the coordinate:
            dims = m_read('dimensions');
            
            mouse = m_read("mouse_pos");
            x = mouse.viewport_x;
            y = mouse.viewport_y;
            
            rois_ch = roi_table(roi_table.channel == chan,:);

            hit = cellfun(@(m) m(y,x), rois_ch.mask);
            hit_idx = find(hit, 1);
            roi_row = rois_ch(hit_idx,:);
            if ~isempty(roi_row)
                roi = table2struct(roi_row); 
               
                if obj.shift_down
                    selection = m_read("roiedit_selected");
                    m_write("roiedit_selected", [roi.roi_id , selection]);
                else
                    m_write("roiedit_selected", roi.roi_id);
                end
            else
                m_write("roiedit_selected", string.empty);
            end
            
            % start drag state:
            obj.drag_state = true;
            m_write("roiselect_drag_points", [x y]);
        end
        
        
        function handled = on_mousemove(obj, manager, view, event)
            [~, m_write, m_read] = manager.data.shorts();
            
            mouse = m_read("mouse_pos");
            x = mouse.viewport_x;
            y = mouse.viewport_y;
            
            % if we are dragging, we add to drag points:
            if obj.drag_state
                obj.drag_points = [obj.drag_points ; x y];
                m_write("roiselect_drag_points", obj.drag_points);
            end
            
            handled = true;
        end
        
        
        function on_mouseup(obj, manager, view, event)
            [~, m_write, m_read] = manager.data.shorts();
            obj.drag_state = false;
            
            points = obj.drag_points;
            if size(points, 1) > 3
                % area to mask:
                mask = true(512, 512);
                [x,y] = find(true(512, 512));
                results = inpolygon(x, y, points(:,2), points(:,1));
                mask(:) = results;
                mask = mask;
                
                % what rois are inside this mask?
                roi_table = m_read("roi_table");
                inside = cellfun(@(m) any(m(:) & mask(:)), roi_table.mask);
                selected = roi_table(inside,:);
                m_write("roiedit_selected", selected.roi_id');
            end
            obj.drag_points = [];   
            
            m_write("roiselect_drag_points", []);
        end


        
        function handled = on_keydown(obj, manager, view, event)
            handled = false;
            obj.shift_down = event.Key == "shift";
        end
        
        
        function handled = on_keyup(obj, manager, view, event)
            handled = false;
            obj.shift_down = false;
            if event.Key == "delete"
                roiman.modes.RoISelect.delete_selection(manager);
            end
        end
        
    end
end

