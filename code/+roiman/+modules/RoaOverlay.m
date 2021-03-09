
classdef RoaOverlay < roiman.ViewModule

    properties
        ax
        img
    end
    
    methods
        function obj = RoaOverlay(name)
            obj@roiman.ViewModule(name, "RoaOverlay");
        end
        
        
        function on_init(obj, manager, view)
            
            dims = manager.data.read('dimensions');
            height = dims(1); 
            width = dims(2);

            % get ax for this view, keep it for updates:
            obj.ax = view.request_ax(height, width, true);
            im = zeros(height,width,3);
            im(:,:,1) = 1;
            obj.img = imagesc(obj.ax, "CData", im);
            obj.img.AlphaData = zeros(height,width);
            
            % Load the roa smoothing parameters into the channel module.
            if view.data.has("channel") && manager.data.has("tseries")
                ts = manager.data.read("tseries");
                channel = view.data.read("channel");
                if ts.has_var("roa_pre_param_hidden")
                    roa_pre_param = ts.load_var("roa_pre_param_hidden");
                    
                    roa_xy_smooth = roa_pre_param(channel).roa_xy_smooth;
                    view.data.write("channel_xy_smoothing",roa_xy_smooth);
                    
                    roa_t_smooth = roa_pre_param(channel).roa_t_smooth;
                    view.data.write("channel_samples",roa_t_smooth);
                    
                    view.data.write("channel_mode","Mean");
                end
            end
            
            view.data.write("roa_alpha",0.7);
            view.data.write("roa_overlay_mode","preview");
            view.data.write("channel_colormap","Bone");
            
            manager.data.assign_changeflag("roa_param","roa_overlay_flagged");
            manager.data.assign_changeflag("roa_param_processed","roa_overlay_flagged");
            manager.data.assign_changeflag("current_frame","roa_overlay_flagged");
            manager.data.assign_changeflag("tseries","roa_overlay_flagged");
            
            view.data.assign_changeflag("viewport","roa_overlay_flagged");
            view.data.assign_changeflag("channel","roa_overlay_flagged");
            view.data.assign_changeflag("roa_overlay_mode","roa_overlay_flagged");
            view.data.assign_changeflag("roa_alpha","roa_overlay_flagged");
            
        end
        
        
        function on_enable(obj, manager, view)
            
        end
        
        
        function on_disable(obj, manager, view)
            
        end
        
        
        function on_update(obj, manager, view)
            [~, ~, m_read, m_flagged] = manager.data.shorts();
            [~, ~, v_read, v_flagged] = view.data.shorts();
            
            if m_flagged("roa_overlay_flagged") || v_flagged("roa_overlay_flagged")
                current_frame = m_read("current_frame");
                chan = v_read("channel");
                
                roa_alpha = v_read("roa_alpha");
                
                roa_overlay_mode = v_read("roa_overlay_mode","");
                
                if roa_overlay_mode == "preview"
                    roa_img_mu = m_read("roa_img_mu_ch"+chan);
                    roa_img_sigma = m_read("roa_img_sigma_ch"+chan);
                    roa_recording = m_read("roa_recording_ch"+chan);
                    
                	if isempty(roa_recording)
                        return;
                    end
                    
                    roa_param = m_read("roa_param");

                    if isempty(roa_param)
                        return;
                    end
                    
                    roa_threshold = roa_param(chan).roa_threshold;
                    roa_ignore_mask = roa_param(chan).roa_ignore_mask;
                    roa_min_size = roa_param(chan).roa_min_size;
                    roa_ignore_border = roa_param(chan).roa_ignore_border;
                    
                    sigma = median(roa_img_sigma(:));

                    % Threshold the video to preview ROA. 
                    mask = roa_recording(:,:,current_frame) > roa_img_mu + roa_threshold*sigma;
                    
                    % Add the ignore border.
                    roa_ignore_mask(1:roa_ignore_border,:) = true;
                    roa_ignore_mask(end-roa_ignore_border+1:end,:) = true;
                    roa_ignore_mask(:,1:roa_ignore_border) = true;
                    roa_ignore_mask(:,end-roa_ignore_border+1:end) = true;
                    
                    % Ignore ROA
                    mask = mask & ~roa_ignore_mask;
                    
                    % Remove small ROA.
                    CC = bwconncomp(mask, 4);
                    num_pixels = cellfun(@numel,CC.PixelIdxList);
                    idx = find(num_pixels < roa_min_size);
                    for i = idx
                        mask(CC.PixelIdxList{i}) = false;
                    end
                elseif roa_overlay_mode == "final_results"
                    mask = m_read("roa_mask_ch"+chan);
                    if isempty(mask)
                        mask = zeros(size(obj.img.AlphaData));
                    else
                        mask = logical(mask(:,:,current_frame));
                    end
                else
                    mask = zeros(size(obj.img.AlphaData));
                end

                if isempty(mask) || ~ismatrix(mask)
                    return;
                end
                
                % Display the mask
                obj.img.AlphaData = mask * roa_alpha;
            end
            
        end
        

    end
end

