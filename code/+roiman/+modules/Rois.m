classdef Rois < roiman.ViewModule
    properties
        ax
        channel
    end
    
    methods
        function obj = Rois(name, channel)
            obj@roiman.ViewModule(name, "rois");
            obj.channel = channel;
        end
        
        
        function on_init(obj, manager, view)
            [~, m_write, m_read] = manager.data.shorts();
            [~, v_write, ~] = view.data.shorts();

            % we render the rois in splines in an axis:
            dims = m_read("dimensions");
            obj.ax = view.request_ax(dims(1), dims(2), true);
            %v_write("roiview_ax", ax);

            % to only render when needed, we remember what version this
            % view last rendered:
            v_write("roiview_table_rendered_version", -1);
            v_write("roiview_selection_rendered_version", -1);
            
            % create a map to keep the splines we have drawn
            % we will store the sp
            v_write("roiview_splines", containers.Map());
            
            m_write("roi_show_rois", true);
            m_write("roi_show_relations", false);
            m_write("roi_show_labels", false);
            
            m_write("roiselect_drag_points", []);
            
            % establish flags for when to redraw:
            m_flag_on = ["roi_table", "roi_show_relations", "roi_show_labels", "roi_show_rois"];
            v_flag_on = ["channel"];
            
            manager.data.assign_changeflag(m_flag_on, "rois_rerender_flagged");
            view.data.assign_changeflag(v_flag_on, "rois_rerender_flagged");
            
            view.data.assign_changeflag("channel", "rois_channel_flagged");
            
            manager.data.assign_changeflag("roiedit_selected", "rois_selection_flagged")
            manager.data.assign_changeflag("roiselect_drag_points", "rois_dragpoints_flagged")
            
            view.data.assign_changeflag("viewport", "rois_zoom_flagged");
        end
        
        
        function on_enable(obj, manager, view)
            %warning("on_enable :: not implemented for " + obj.name);
        end
        
        
        function on_disable(obj, manager, view)
           %warning("on_disable :: not implemented for " + obj.name);
        end
        
        
        function on_update(obj, manager, view)
            [m_has, ~, m_read, m_flagged] = manager.data.shorts();
            [v_has, ~, v_read, v_flagged] = view.data.shorts();
            
            % note: we cannot use is_obsolete here because we compare thew view
            % with the manager, while obso only works with one.
            % FIXME: make func for this pattern too?
            
            % only re-render if the roi table has been update since we last
            % drew:
            has_rois = m_has("roi_table");
            if ~has_rois
                return;
            end
            
            if (m_flagged("rois_rerender_flagged") || v_flagged("rois_rerender_flagged")) && m_has("roi_table")
                obj.update_roi_splines(manager, view);
                obj.update_roi_relations(manager, view);
                obj.update_roi_labels(manager, view);
                obj.update_selection(manager, view);
                if m_read("debug_report_spline_redraws", false)
                    disp("Splines updated");
                end
            end
            
            % update selection:
            if m_flagged("rois_selection_flagged")
                obj.update_selection(manager, view);
                if m_read("debug_report_spline_redraws", false)
                    disp("Selection splines color updated");
                end
            end
            
            % update visibility by channel:
            if v_flagged("rois_channel_flagged")
                chan = v_read("channel");
                splinemap = v_read("roiview_splines");
                for key = splinemap.keys
                    splines = splinemap(key{:});
                    for spline = splines
                        spline.Visible = spline.UserData.channel == chan;
                    end
                end
            end
            
            % draw selection drag rect, if any:
            if m_flagged("rois_dragpoints_flagged") 
                obj.update_drag_rect(manager, view);
            end
            
            if v_flagged("rois_zoom_flagged") && v_has("viewport")
                vp = v_read("viewport");
                x = vp(1); 
                y = vp(2); 
                w = vp(3); 
                h = vp(4); 
                xlim(obj.ax, [x, x + w]);
                ylim(obj.ax, [y, y + h]);
            end
        end
        
        function update_drag_rect(obj, manager, view)
            [~, ~, m_read, ~] = manager.data.shorts();
            [~, v_write, v_read, ~] = view.data.shorts();
            
            %ax = v_read("roiview_ax");
            drag_points = m_read("roiselect_drag_points", []);
            dims = m_read("dimensions");
            
            view.data.delete_on_inner("roi_drag_patch");
            
            if isempty(drag_points)
                return;
            end
            h = patch(obj.ax, drag_points(:,1), drag_points(:,2), [1 1 1], 'FaceAlpha', .1, 'EdgeColor', 'white');
            v_write("roi_drag_patch", h);
        end
        
        
        function update_roi_splines(obj, manager, view)
            [~, m_write, m_read] = manager.data.shorts();
            [~, v_write, v_read] = view.data.shorts();
  
            chan = v_read("channel");
            [roi_table, v] = m_read("roi_table");
            splinemap = v_read("roiview_splines");

            
            % remove any splines in the map that is not in the roi table:
            % these have been removed since last update:
            for key = splinemap.keys
                if ~any(contains(roi_table.roi_id, key))
                    delete(splinemap(key{:}));
                    splinemap.remove(key);
                end
            end
            
            % now the other way - paint any rois that are in the table, but
            % not in the map:
            n = height(roi_table);
            for i = 1:n
                roi = table2struct(roi_table(i,:));
                if ~any(contains(splinemap.keys, roi.roi_id))
                    [B,~,~,~] = bwboundaries(roi.mask);
                    
                    handles = cell.empty;
                    for k = 1:length(B)
                        boundary = B{k};

                        h = plot(obj.ax, boundary(:,2), boundary(:,1), 'LineWidth', 2, 'Color', 'white');
                        h.UserData = roi;
                        h.ButtonDownFcn = @(~,~) disp("Event");
                        handles = [handles, h];
                    end
                    splinemap(roi.roi_id) = handles;
                end
            end
            
            % set update to be uneccesary:
            v_write("roiview_table_rendered_version", v);
        end
        
        function update_roi_relations(obj, manager, view)
            [~, m_write, m_read] = manager.data.shorts();
            [~, v_write, v_read] = view.data.shorts();
            
            relmap = v_read("roiview_relations", containers.Map());
            dims = m_read("dimensions");
            
            chan = v_read("channel");
            roi_table = m_read("roi_table");
            roi_table = roi_table(roi_table.channel == chan,:);
            
            % clear existing relation arrows:
            for key = relmap.keys
                delete(relmap(key{:}));
                relmap.remove(key{:});
            end
            
            % if we are not showing relations, we stop here:
            if ~m_read("roi_show_relations", true)
                return;
            end
            
            % recreate:
            for r = 1:height(roi_table)
                roi = table2struct(roi_table(r,:));
                if ismissing(roi.parent_id)
                    continue;
                end
                
                % FIXME: annotations work on currennt figure, which is not
                % good - we want this to render in the axis?
                
                % draw arrow:
                parent_row = roi_table(roi_table.roi_id == roi.parent_id,:);
                parent = table2struct(parent_row);
                xs = round([parent.center_x; roi.center_x ]) / dims(1);
                ys = 1 - (round([parent.center_y; roi.center_y]) / dims(2));
                %h = annotation('arrow', xs, ys);
                h = line(xs, ys);
                h.Color = "white";
%                 h.LineWidth = .5;
%                 h.HeadWidth = 3;
%                 h.HeadLength = 3;
                relmap(roi.roi_id) = h;
            end
            
            v_write("roiview_relations", relmap);
        end
        
        
        function update_roi_labels(obj, manager, view)
            [~, m_write, m_read] = manager.data.shorts();
            [~, v_write, v_read] = view.data.shorts();
            
            labmap = v_read("roiview_labels", containers.Map());
            dims = m_read("dimensions");
            
            chan = v_read("channel");
            roi_table = m_read("roi_table");
            roi_table = roi_table(roi_table.channel == chan,:);
            
            % clear existing relation arrows:
            for key = labmap.keys
                delete(labmap(key{:}));
                labmap.remove(key{:});
            end
            
            % if we are not showing relations, we stop here:
            if ~m_read("roi_show_labels")
                return;
            end
            
            % recreate:
            for r = 1:height(roi_table)
                roi = table2struct(roi_table(r,:));
                h = text(obj.ax, roi.center_x, roi.center_y, roi.short_name, 'Color','white', 'FontSize',6);
                labmap(roi.roi_id) = h;
            end
            
            v_write("roiview_labels", labmap);
        end
               
        function update_selection(obj, manager, view)
            [~, m_write, m_read] = manager.data.shorts();
            [~, v_write, v_read] = view.data.shorts();
            
            [selected, v] = m_read("roiedit_selected");
            splinemap = v_read("roiview_splines");
            
            for key = splinemap.keys
                splines = splinemap(key{:});
                if any(contains(selected, key{:}))
                    for spline = splines
                        spline.Color = "red";
                    end
                else
                    for spline = splines
                        spline.Color = "white";
                    end
                end
            end
            
            v_write("roiview_selection_rendered_version", v);
        end
 
    end
end

