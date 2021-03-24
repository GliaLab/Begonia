classdef RoIPolygon < roiman.Mode

    properties
        HELP_MSG = "Paint RoIs by clicking points that will form their outline.";
        GUIDE_TEXT = "*ROI-POLYGON MODE*\nPress escape to return to idle mode\n\nSpace: finish current rRoI\nTab/shift-type: cycle type\n1-9: set type\n0: list types\nShift-1-9: set channel";
    
        markers
    end
    
    methods
        
        function obj = RoIPolygon()
            obj = obj@roiman.Mode("ROI:POLYGON", "rpol");
        end
        
        
        function on_init(obj, manager)
            obj.markers = [];
            
        end
        
        
        function on_activate(obj, manager)
            [~, m_write, ~] = manager.data.shorts();
            
            m_write("message", obj.HELP_MSG)
            m_write("guide_text", replace(obj.GUIDE_TEXT, "\n", newline))
            
            % "RoiPolygonOverlay" module should pick this up, and
            % display curren controls:
            m_write("roipolygon_overlay_on", true)
            
            for view = manager.views
                view.figure.Pointer = 'crosshair';
            end
        end
        
        
        function on_deactivate(obj, manager)
            [~, m_write, m_read] = manager.data.shorts();
            
            if m_read("message") == obj.HELP_MSG
                m_write("message", "");
            end
            
            % this should cause  "RoiPolygonOverlay" module to hide the
            % controls 
            m_write("roipolygon_overlay_on", false)
            
            for view = manager.views
                view.figure.Pointer = 'arrow';
            end
        end
        
        
        function on_keyboard(obj, type, manager, combo, event)
            [~, m_write, m_read] = manager.data.shorts();
            
            % space finishes roi:
            if event.Key == "space" && type == "up"
                roiman.modes.RoIPolygon.finish_roi(manager);
            end
                 
            % tab cycles roi (uses the RoI Paint mode's functions) :
            if event.Key == "tab" && isempty(event.Modifier) && type == "up"
                roiman.modes.RoIPaint.cycle_roi_type(manager, 1);
            elseif event.Key == "tab" && any(event.Modifier == "shift")  && type == "up"
                roiman.modes.RoIPaint.cycle_roi_type(manager, -1);
            end

            % numeric keys choose roi type (uses the RoI Paint mode's functions):
            num = str2double(event.Key);
            if ~isnan(num) && isempty(event.Modifier)
                roiman.modes.RoIPaint.set_roi_type_by_number(manager, num);
            elseif ~isnan(num) && any(event.Modifier == "shift")
                manager.current_view.data.write("channel", num);
            end

        end
        
        
        function on_mouse(obj, type, manager, view, event)
            % for this module, handling the marker interaction is probably
            % better done in the module
        end
        
    end
    
    
    methods (Static)
        
        %% Creates a RoI in the roi table:
        function finish_roi(manager)
            [~, m_write, m_read] = manager.data.shorts();
            [~, ~, v_read] = manager.current_view.data.shorts();
            
            % add generation of roi mask from polygons here:
            warning("")
            mask = []
            
            ts = m_read("tseries");
            type = m_read("roiedit_roi_type");
            [ys,xs] = find(mask);   % nice trick, Daniel :D
            
            tab = m_read("roi_table");
          
            short_name = string(begonia.util.make_snowflake_id(char(type)));
            area_px2 = sum(mask(:));   
            center_x = mean(xs);
            center_y = mean(ys);
            center_z = m_read("z_plane");
            translations = {[]};
            channel = v_read("channel");
            mask = {mask};
            parent_id = missing();
            roi_id = type + string(begonia.util.make_uuid());
            shape = "polygon";
            source_id = string(ts.name);
            tags = " ";
            version = "RM2 1.0";
            z_idx = 1;
            roiarray_source = struct();
            added = datetime();
            
            if isempty(parent_id)
                parent_id = " ";
            end
                
            roi = table(short_name, area_px2, center_x, center_y, center_z, translations, channel, mask, parent_id, roi_id,...
                shape, source_id, tags, type, version, z_idx, roiarray_source, added);
            
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
            roiman.modes.RoIPolygon.clear_markers(manager);
        end
        
        function clear_markers(manager)
            warning("clear makers not implemented")
        end
        
    end
end

