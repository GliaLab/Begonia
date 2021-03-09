classdef RoISelect < roiman.Mode

    properties
        HELP_MSG = "Select rois by clicking/dragging";
        GUIDE_TEXT = "*ROI-SELECT*\n\nClick: select RoI\nShift click: add to selection\nDrag: Select area\ns : split selected by component\np : set parent to first selected\nshift-p : clear parents";
    
        drag_state
        drag_points
        shift_down
    end
    
    methods
        
        function obj = RoISelect()
            obj = obj@roiman.Mode("ROI:SELECT", "rs");
            obj.drag_state = false;
            obj.shift_down = false;
            obj.drag_points = [];
        end
        
        
        function on_init(obj, manager)
            
        end
        
        
        function on_activate(obj, manager)
            [m_has, m_write, d_read] = manager.data.shorts();
            
            m_write("message", obj.HELP_MSG)
            m_write("guide_text", replace(obj.GUIDE_TEXT, "\n", newline))
        end
        
        
        function on_deactivate(obj, manager)
            [~, m_write, m_read] = manager.data.shorts();
            
            m_write("roiedit_selected", string.empty);
        end
        
        
        function on_keyboard(obj, type, manager, combo, event)
            if type == "down"
                % for multi-select clicks, we need to know if shift is down:
                obj.shift_down = event.Key == "shift";
            
            elseif type == "up"
                obj.shift_down = false;
                
                if event.Key == "delete"
                    roiman.modes.RoISelect.delete_selection(manager);
                end

                % shortcuts:
                if lower(event.Key) == "s"
                    roiman.modes.RoISelect.split_selected(manager);
                end

                if lower(event.Key) == "p" && isempty(event.Modifier)
                    roiman.modes.RoISelect.set_parent_from_selected(manager);
                elseif lower(event.Key) == "p" && event.Modifier == "shift"
                    roiman.modes.RoISelect.clear_parents_from_selected(manager);
                end
            end
            
        end
        
        
        function on_mouse(obj, type, manager, view, event)
            if type == "move"
                obj.handle_mousemove(manager, view, event)
            elseif type == "down"
                obj.handle_mousedown(manager, view, event)
            elseif type == "up"
                obj.handle_mouseup(manager, view, event)
            end
        end
        
        
        function handle_mouseup(obj, manager, view, event) 
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
        
        
        function handle_mousedown(obj, manager, view, event) 
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
        
        function handle_mousemove(obj, manager, view, event) 
            [~, m_write, m_read] = manager.data.shorts();
            
            mouse = m_read("mouse_pos");
            x = mouse.viewport_x;
            y = mouse.viewport_y;
            
            % if we are dragging, we add to drag points:
            if obj.drag_state
                obj.drag_points = [obj.drag_points ; x y];
                m_write("roiselect_drag_points", obj.drag_points);
            end
        end
        
        
    end
    
    
    
    methods (Static)
        function set_parent_from_selected(manager)
            [~, m_write, m_read] = manager.data.shorts();
            selected = m_read("roiedit_selected");
            
            if length(selected) < 2
                error("Need more than one selected RoI to set parent");
            end
            
            roi_tab = m_read("roi_table");
            roi_tab_orig = roi_tab;
            
            parent_id = selected(1);
            children = selected(2:end);
            
            for child_id = children
                idx = find(roi_tab.roi_id == child_id);
                roi_tab.parent_id(idx) = parent_id;
            end
            
            % add to memento:
            function do(); m_write("roi_table", roi_tab); end
            function undo(); m_write("roi_table", roi_tab_orig);end
            manager.memento.do(@do, "Set parents", @undo);
        end
        
        
        function clear_parents_from_selected(manager)
            [~, m_write, m_read] = manager.data.shorts();
            
            selected = m_read("roiedit_selected");
            roi_table = m_read("roi_table");
            roi_table_orig = roi_table;
            
            for roi_id = selected
                idx = find(roi_table.roi_id == roi_id);
                roi_table.parent_id(idx) = missing;
            end
            m_write("roi_table", roi_table);
            
            % add to memento:
            function do(); m_write("roi_table", roi_table); end
            function undo(); m_write("roi_table", roi_table_orig);end
            manager.memento.do(@do, "Clear parents", @undo);
        end
        
        
        function delete_selection(manager)
            [~, m_write, m_read] = manager.data.shorts();
            
            selected = m_read("roiedit_selected");
            roi_tab = m_read("roi_table");
            roi_tab_orig = roi_tab;
            
            for id = selected
                roi_tab = roi_tab(roi_tab.roi_id ~= id,:);
            end
            
            % add changes to memento:
            function do()
                m_write("roi_table", roi_tab);
                m_write("roiedit_selected", string.empty);
            end
            
            function undo()
                m_write("roi_table", roi_tab_orig);
                m_write("roiedit_selected", selected);
            end
            
            manager.memento.do(@do, "Delete rois", @undo);
        end
        
        function split_selected(manager)
            [~, m_write, m_read] = manager.data.shorts();
            
            selected = m_read("roiedit_selected");
            roi_table = m_read("roi_table");
            
            roi_tab_orig = roi_table;   % for memento
            
            for id = selected
                roi = roi_table(roi_table.roi_id == id,:);
                mask = roi.mask{:};
                comps = bwconncomp(mask);

                for area = comps.PixelIdxList
                    submask = false(size(mask));
                    submask(area{:}) = true;

                    [ys,xs] = find(submask);

                    new_roi = roi;
                    new_roi.short_name = string(begonia.util.make_snowflake_id(char(roi.type)));
                    new_roi.roi_id = string(begonia.util.make_uuid());
                    new_roi.area_px2 = sum(submask(:));
                    new_roi.center_x = mean(xs);
                    new_roi.center_y = mean(ys);
                    new_roi.mask = {submask};
                    roi_table = [roi_table ; new_roi]; %#ok<AGROW>
                end

                roi_table = roi_table(roi_table.roi_id ~= roi.roi_id,:);
            end 
            
            % add changes to memento:
            function do()
                m_write("roi_table", roi_table);
                m_write("roiedit_selected", string.empty);
            end
            
            function undo()
                m_write("roi_table", roi_tab_orig);
                m_write("roiedit_selected", selected);
            end
            
            manager.memento.do(@do, "Split RoI(s)", @undo);
        end
        
        
        function change_selection_type(manager, type)
            [~, m_write, m_read] = manager.data.shorts();
            
            selected = m_read("roiedit_selected");
            roi_table = m_read("roi_table");
            roi_table_orig = roi_table;
            
            for id = selected
                idx = find(roi_table.roi_id == id);
                roi_table.type(idx) = type;
            end
            
           % add changes to memento:
            function do(); m_write("roi_table", roi_table); end
            function undo(); m_write("roi_table", roi_tab_orig);end
            manager.memento.do(@do, "Change RoI type to " + type, @undo);
        end
        
        
        function select_last(manager)
            [~, m_write, m_read] = manager.data.shorts();
            roi_table = m_read("roi_table");
            
            if isempty(roi_table)
                m_write("message", "Error: no rois to select");
                beep;
                return;
            end
            
            [~, idx] = max(roi_table.added);
            last_id = roi_table.roi_id(idx);
            m_write("roiedit_selected", last_id);
            manager.set_mode("ROI:SELECT")
        end
        
    end
end

