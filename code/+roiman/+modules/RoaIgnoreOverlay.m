
classdef RoaIgnoreOverlay < roiman.ViewModule

    properties
        ax
        img
        circle
    end
    
    methods
        function obj = RoaIgnoreOverlay(name)
            obj@roiman.ViewModule(name, "RoaIgnoreOverlay");
        end
        
        
        function on_init(obj, manager, view)
            dims = manager.data.read('dimensions');
            height = dims(1); 
            width = dims(2);

            % get ax for this view, keep it for updates:
            obj.ax = view.request_ax(height, width, true);
            im = zeros(height,width,3);
            im(:,:,3) = 1;
            obj.img = imagesc(obj.ax, "CData", im);
            obj.img.AlphaData = zeros(height,width);
            
            view.data.write("roa_ignore_alpha",0.7);
            
            manager.data.assign_changeflag("roa_param","roa_ignore_overlay_flagged");
            manager.data.assign_changeflag("roa_param_processed","roa_ignore_overlay_flagged");
            manager.data.assign_changeflag("mouse_pos","roa_ignore_overlay_flagged");
            manager.data.assign_changeflag("roa_ignore_brush_size","roa_ignore_overlay_flagged");
            
            view.data.assign_changeflag("viewport","roa_ignore_overlay_flagged");
            view.data.assign_changeflag("channel","roa_ignore_overlay_flagged");
            view.data.assign_changeflag("roa_ignore_alpha","roa_ignore_overlay_flagged");
            view.data.assign_changeflag("roa_overlay_mode","roa_ignore_overlay_flagged");
            
        end
        
        
        function on_enable(obj, manager, view)
            
        end
        
        
        function on_disable(obj, manager, view)
            
        end
        
        
        function on_update(obj, manager, view)
            [~, ~, m_read, m_flagged] = manager.data.shorts();
            [~, ~, v_read, v_flagged] = view.data.shorts();
            
            if m_flagged("roa_ignore_overlay_flagged") || v_flagged("roa_ignore_overlay_flagged")
                chan = v_read("channel");
                
                roa_ignore_alpha = v_read("roa_ignore_alpha");
                
                roa_overlay_mode = v_read("roa_overlay_mode","");
                
                if roa_overlay_mode == "preview"
                    roa_param = m_read("roa_param");
                    mask = roa_param(chan).roa_ignore_mask;
                    roa_ignore_border = roa_param(chan).roa_ignore_border;
                elseif roa_overlay_mode == "final_results"
                    roa_param_processed = m_read("roa_param_processed");
                    mask = roa_param_processed(chan).roa_ignore_mask;
                    roa_ignore_border = roa_param_processed(chan).roa_ignore_border;
                end
                
                if isempty(mask)
                    mask = zeros(size(obj.img.AlphaData));
                end
                
                % Add the ignore border.
                mask(1:roa_ignore_border,:) = true;
                mask(end-roa_ignore_border+1:end,:) = true;
                mask(:,1:roa_ignore_border) = true;
                mask(:,end-roa_ignore_border+1:end) = true;
                
                % Display the mask
                obj.img.AlphaData = mask * roa_ignore_alpha;
                
                mode = m_read("mode");
                if mode.name == "ROA:IGNORE"
                    % render cricle on mouse position:
                    mouse_pos = m_read("mouse_pos");
                    brush_px = m_read("roa_ignore_brush_size");
                    pos = [mouse_pos.viewport_x, mouse_pos.viewport_y];

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
                elseif mode.name == "IDLE"
                    if ~isempty(obj.circle)
                        delete(obj.circle);
                    end
                end
            end
            
        end
        

    end
end

