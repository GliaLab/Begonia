%{
Overlay that visualises an area that is being painted and the brush size
outline. Responds to ROI-PAINT mode.
%}
classdef RoIPaintOverlay < roiman.ViewModule

    properties
        ax
        img
        circle
        
        KEY_MASK = "roipaint_mask"
        
        KEY_ROI_TYPE = "roiedit_roi_type"
        KEY_ROI_TYPE_AVAILABLE = "roiedit_roi_types_available"
        
        KEY_BRUSH_CIRCLE_H = "roipaint_brush_circle_h"
        KEY_BRUSH_SIZE_PX = "roipaint_brush_size_px";
    end
    
    methods
        function obj = RoIPaintOverlay(name)
            obj@roiman.ViewModule(name, "roipaintoverlay");
        end
        
        function mask = reset_mask(obj, manager) 
            [~, m_write, ~] = manager.data.shorts();
            
            m_write("roipaint_overlay_on", false);
            [w,h] = obj.get_wh(manager);
            
            mask = false(w, h);
            m_write(obj.KEY_MASK, mask);
        end
        
        
        function [w, h] = get_wh(obj, manager)
            dims = manager.data.read('dimensions');
            w = dims(1); 
            h = dims(2);
        end
        
        
        function on_init(obj, manager, view)
            [~, v_write, ~] = view.data.shorts();
            
            [w,h] = obj.get_wh(manager);

            % get ax for this view, keep it for updates:
            obj.ax = view.request_ax(w, h, true);
            obj.img = imagesc(obj.ax, "CData", false(w, h));
            
            obj.reset_mask(manager);
            
            % pay attention to zoom level:
            view.data.assign_changeflag(["viewport"], "roipaint_flagged");
            manager.data.assign_changeflag(["roipaint_overlay_on", "mouse_pos", "roipaint_brush_size_px"], "roipaint_flagged");
        end
        
        
        function on_enable(obj, manager, view)
            
        end
        
        
        function on_disable(obj, manager, view)
            
        end
        
        
        function on_update(obj, manager, view)
            [~, m_write, m_read, m_flagged] = manager.data.shorts();
            [~, ~, v_read, v_flagged] = view.data.shorts();
            
            mask = m_read(obj.KEY_MASK);

            if m_flagged("roipaint_flagged") || v_flagged("roipaint_flagged")
                overlay_on = m_read('roipaint_overlay_on');

                if ~overlay_on
                    obj.ax.Visible = 'off';
                    obj.img.Visible = 'off';
                else
                    obj.ax.Visible = 'on';
                    obj.img.Visible = 'on';
                    obj.img.CData = mask;
                    obj.img.AlphaData = mask * 0.5;

                    % render cricle on mouse position:
                    mouse_pos = m_read("mouse_pos");
                    brush_px = m_read("roipaint_brush_size_px");
                    pos =  [mouse_pos.viewport_x, mouse_pos.viewport_y];

                    % this approach is due to annotations being figure level,
                    % not axis level. 
                    % FIXE: update X and Y points rather than delete old.
                    old_circ = obj.circle;
                    obj.circle = viscircles(obj.ax, pos, brush_px, ...
                        'LineStyle','-', ...
                        "LineWidth", 1, ...
                        "Color", "white", ...
                        "EnhanceVisibility", false);

                    if ~isempty(old_circ)
                        delete(old_circ)
                    end

                    % apply zoom:
                    vp = v_read("viewport");
                    x = vp(1); 
                    y = vp(2); 
                    w = vp(3); 
                    h = vp(4); 
                    xlim(obj.ax, [x, x + w]);
                    ylim(obj.ax, [y, y + h]);
                end
            end
        end
        

    end
end

