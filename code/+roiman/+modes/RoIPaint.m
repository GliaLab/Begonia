classdef RoIPaint < roiman.Mode

    properties
        HELP_MSG = "Paint rois by clicking or clicking and dragging";
        GUIDE_TEXT = "*ROI-PAINT*\nPress escape to return to idle mode\n\nDrag: mark roi area\nScroll: to change brush size\nShift-Scroll: move time\nSpace: finish\nTab/shift-type: cycle type\n1-9: set type\n0: list types\ns : toggle subtract brush\nShift-1-9: set channel";
    
        drag_state
        shift_down
    end
    
    methods
        
        function obj = RoIPaint()
            obj = obj@roiman.Mode("ROI:PAINT", "rp");
            obj.drag_state = false;
            obj.shift_down = false;
        end
        
        
        function on_init(~, manager)
            % initial brush size:
            roiman.modes.RoIPaint.set_brush(manager, 10, "set");
        end
        
        
        function on_activate(obj, manager)
            [~, m_write, ~] = manager.data.shorts();
            
            m_write("message", obj.HELP_MSG)
            m_write("guide_text", replace(obj.GUIDE_TEXT, "\n", newline))
            m_write("roipaint_overlay_on", true)
            
            for view = manager.views
                view.figure.Pointer = 'crosshair';
            end
        end
        
        
        function on_deactivate(obj, manager)
            [~, m_write, m_read] = manager.data.shorts();
            
            if m_read("message") == obj.HELP_MSG
                m_write("message", "");
            end
            
            m_write("roipaint_overlay_on", false)
            
            for view = manager.views
                view.figure.Pointer = 'arrow';
            end
        end
        
        
        function on_keyboard(obj, type, manager, combo, event)
            [~, m_write, m_read] = manager.data.shorts();
            
            if type == "down"
                obj.shift_down = event.Key == "shift";
            else
                obj.shift_down = false;
            end
            
            % space finishes roi:
            if event.Key == "space" && type == "up"
                roiman.modes.RoIPaint.finish_roi(manager);
            end
                 
            % tab cycles roi:
            if event.Key == "tab" && isempty(event.Modifier) && type == "up"
                roiman.modes.RoIPaint.cycle_roi_type(manager, 1);
            elseif event.Key == "tab" && any(event.Modifier == "shift")  && type == "up"
                roiman.modes.RoIPaint.cycle_roi_type(manager, -1);
            end

            % numeric keys choose roi type:
            num = str2double(event.Key);
            if ~isnan(num) && isempty(event.Modifier)
                roiman.modes.RoIPaint.set_roi_type_by_number(manager, num);
            elseif ~isnan(num) && any(event.Modifier == "shift")
                manager.current_view.data.write("channel", num);
            end
            
            % s toggles subtract mode:
            if lower(event.Key) == "s" && type == "up"
                operation = m_read("roipaint_operation");
                if operation == "subtract"
                    m_write("roipaint_operation", "add");
                    m_write("message", "Brush: add");
                else
                    m_write("roipaint_operation", "subtract");
                    m_write("message", "Brush: subtract");
                end
            end
            
        end
        
        
        function on_mouse(obj, type, manager, view, event)
            [~, m_write, m_read] = manager.data.shorts();
            
            if type == "wheel" && obj.shift_down == false
                px = event.VerticalScrollCount;
                roiman.modes.RoIPaint.set_brush(manager, px, "increment");
                
            elseif type == "down"
                % click always stamps a roi:
                mouse = manager.data.read("mouse_pos");
                roiman.modes.RoIPaint.add_to_mask(manager, mouse.viewport_x, mouse.viewport_y);
                
                % start drag state:
                obj.drag_state = true;
                
            elseif type == "move" && obj.drag_state
                % continue drawing if we are in the draw state:
                mouse = manager.data.read("mouse_pos");
                roiman.modes.RoIPaint.add_to_mask(manager, mouse.viewport_x, mouse.viewport_y);
                
            elseif type == "up"
                obj.drag_state = false;
            end
            
            if obj.shift_down && type == "wheel"
                dist = event.VerticalScrollCount * event.VerticalScrollAmount;
                frame = m_read("current_frame");
                frames = m_read("frames");
                
                frame = frame - dist;
                if frame <= 0
                    frame = frames(end) + frame;
                    m_write("message", "LOOPED TO END");
                elseif frame > frames(end)
                    frame = frame - frames(end);
                    m_write("message", "LOOPED TO START");
                end
                manager.goto(frame)
            end
            
        end
        
    end
    
  
    
    
    methods (Static)
        
        function add_to_mask(manager, x, y)
            [~, m_write, m_read] = manager.data.shorts();
            
            mask = m_read("roipaint_mask");
            brush_mask = m_read("roipaint_brush_mask");
            pix_to_dunit = m_read("pix_to_dunit");
            dunit = m_read("dunit");
            operation = m_read("roipaint_operation");
            
            bw = size(brush_mask, 1) - 1;
            bh = size(brush_mask, 2) - 1;
            
            xs = (x - round(bw/2));
            xe = xs + bw;
            ys = (y - round(bh/2));
            ye = ys + bh;

            % ensure no x or y is below zero:
            xs = xs(find(xs >= 1));
            ys = ys(find(ys >= 1));
            
            source = mask(ys:ye, xs:xe);
            if operation == "add"
                mask(ys:ye, xs:xe) = brush_mask | source;
            elseif operation == "subtract"
                mask(ys:ye, xs:xe) = source - (source & brush_mask);
            end
            m_write("roipaint_mask", mask);
            
            % inform size marked:
            area_px2 = round(pix_to_dunit(sum(mask(:))), 1);
            m_write("message", area_px2 + " " + dunit + "2");
        end
        
        
        function cycle_roi_type(manager, delta)
            [~, m_write, m_read] = manager.data.shorts();
            
            types = m_read("roiedit_roi_types_available");
            current = m_read("roiedit_roi_type");
            
            idx = find(current == types.type);
            n = length(types.type);
            idx = idx + delta;
            if idx > n
                idx = 1;
            elseif idx < 1
                idx = n;
            end
            m_write("roiedit_roi_type", types.type(idx));
            m_write("message", types.desc(idx));
        end
        
        
        function set_roi_type_by_number(manager, roi_num)
            [~, m_write, m_read] = manager.data.shorts();
            
            types = m_read("roiedit_roi_types_available");
            current = m_read("roiedit_roi_type");
            n = length(types.type);
            if roi_num > n
                m_write("Message", "No RoI type with this number")
                return;
            elseif roi_num < 1
                list = roiman.modes.RoIPaint.get_roi_type_list_str(manager);
                m_write("message", list);
                return;
            end
            
            m_write("roiedit_roi_type", types.type(roi_num));
            m_write("message", types.type(roi_num) + " | " + types.desc(roi_num));
        end
       
        
        function list = get_roi_type_list_str(manager)
            [~, ~, m_read] = manager.data.shorts();
            
            types = m_read("roiedit_roi_types_available");
            list = string.empty;
            i = 1;
            for type = types.type'
                list = [list ; string(i) + ":" + type];
                i = i + 1;
            end
            
            list = join(list, " ");
        end
        
        
        %% Creates a RoI in the roi table from the current roi mask.
        function finish_roi(manager)
            [~, m_write, m_read] = manager.data.shorts();
            [~, ~, v_read] = manager.current_view.data.shorts();
            
            ts = m_read("tseries");
            mask = m_read("roipaint_mask");
            if sum(mask,'all') == 0
                return
            end
            type = m_read("roiedit_roi_type");
            [ys,xs] = find(mask);   % nice trick, Daniel :D
            
            tab = m_read("roi_table");
          
            short_name = string(begonia.util.make_snowflake_id(char(type)));
            area_px2 = sum(mask(:));  
            if area_px2 == 0
                return;
            end
            
            center_x = mean(xs);
            center_y = mean(ys);
            center_z = m_read("z_plane");
            translations = {[]};
            channel = v_read("channel");
            mask = {mask};
            parent_id = missing();
            roi_id = type + string(begonia.util.make_uuid());
            shape = "paint";
            source_id = string(ts.name);
            tags = " ";
            version = "RM2 1.0";
            z_idx = 1;
            roiarray_source = struct();
            added = datetime();
            metadata = struct();
            
            if isempty(parent_id)
                parent_id = " ";
            end
                
            roi = table(short_name, area_px2, center_x, center_y, center_z, translations, channel, mask, parent_id, roi_id,...
                shape, source_id, tags, type, version, z_idx, roiarray_source, added, metadata);
            
            % install in memento:
            tab_orig = tab;
            function do()
                tab = [tab; roi]; % this appears faster than extending the table fields
                m_write("roi_table", tab);
            end
            
            function undo()
                m_write("roi_table", tab_orig);
            end
            
            manager.memento.do(@do, "Add " + type + " RoI", @undo);
            roiman.modes.RoIPaint.clear_roi(manager);
        end
        
        function clear_roi(manager)
            dims = manager.data.read("dimensions");
            mask = false(dims(2), dims(1));
            manager.data.write("roipaint_mask", mask);
        end
        
        function set_brush(manager, px, action)
            
            if action == "increment"
                brush_px = manager.data.read("roipaint_brush_size_px");
                brush_px = px + brush_px;
            elseif action == "set"
                brush_px = px;
            end
            
            if brush_px < 1
                brush_px = 1;
            elseif brush_px > 100
                brush_px = 100;
            end

            manager.data.write("roipaint_brush_size_px", brush_px);

            se = strel('disk', brush_px, 0); 
            brush_mask = se.Neighborhood;
            manager.data.write("roipaint_brush_mask", brush_mask);
        end
        
    end
end

