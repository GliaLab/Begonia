classdef Channel < roiman.ViewModule
    properties
        channel
        matkey
        cdatakey
        modekey
        modedatakey
        
        chmean_key
        chstd_key
        chmax_key
        
        ax
        img
    end
    
    methods
        function obj = Channel(name, channel)
            obj@roiman.ViewModule(name, "channel");
            obj.channel = channel;
        end
        
        
        function on_init(obj, manager, view)
            [m_has, m_write, m_read] = manager.data.shorts();
            [~, v_write, v_read] = view.data.shorts();
            
            dims = m_read("dimensions");
            
            obj.matkey = "ch" + obj.channel + "_MAT";
            obj.cdatakey = "ch" + obj.channel + "_CDATA";
            obj.cdatakey = "ch" + obj.channel + "_MODE";
            obj.cdatakey = "ch" + obj.channel + "_MODEDATA";
            
            obj.chmean_key = "ch" + obj.channel + "_mean";
            obj.chstd_key = "ch" + obj.channel + "_std";
            obj.chmax_key = "ch" + obj.channel + "_max";
            
            v_write("channel", obj.channel);    % channel # being displayed
            v_write("channel_mode", "Mean");
            v_write("channel_samples", 30);
            v_write("channel_xy_smoothing", 0);
            v_write("channel_colormap", "begonia.colormaps.turbo");
            v_write("channel_low", 0);
            v_write("channel_high", 1);
            
            % flags to trigger redraw when needed only:
            m_flag_on = ["current_frame", "tseries"];
            v_flag_on = [...
                "channel", "viewport", "channel_mode" ...
                , "channel_samples", "channel_xy_smoothing" ...
                , "channel_colormap", "channel_low", "channel_high"];
            
            manager.data.assign_changeflag(m_flag_on, "channel_redraw_flagged");
            view.data.assign_changeflag(v_flag_on, "channel_redraw_flagged");
            
            % request an imagesc on the current view:
            [h, ax] = view.request_imagesc(dims(1), dims(2), true);
            ax.Color = "black";
            obj.ax = ax;
            obj.img = h;
            
            view.zoom_reset();
        end
        
        
        function on_enable(obj, manager, view)
            %warning("on_enable :: not implemented for " + obj.name);
        end
        
        
        function on_disable(obj, manager, view)
            %warning("on_disable :: not implemented for " + obj.name);
        end
        
        
        function on_update(obj, manager, view)
            [m_has, m_write, m_read, m_flagged] = manager.data.shorts();
            [~, v_write, v_read, v_flagged] = view.data.shorts();
            
            % only re-render if we have to:
            if ~m_flagged("channel_redraw_flagged") && ~v_flagged("channel_redraw_flagged")
                return;
            end
            
            ax = obj.ax;
            
            chan = v_read("channel");
            mode = v_read("channel_mode");
            frame = m_read('current_frame');
            low = v_read('channel_low');
            high = v_read('channel_high');
            cmap = v_read('channel_colormap');
            
            mat = m_read("matrix_ch_" + chan);
            
            if mode == "Mean" 
                data = obj.get_range(frame, mat, view);
                data = mean(data, 3);
                data = obj.spatially_smooth_img(view,data);
            elseif mode == "Std."
                data = obj.get_range(frame, mat, view);
                data = std(double(data), 1, 3);
                data = obj.spatially_smooth_img(view,data);
            elseif mode == "Max"
                data = obj.get_range(frame, mat, view);
                data = max(data, [], 3);
                data = obj.spatially_smooth_img(view,data);
            elseif mode == "Mean (full series)"
                data = m_read("ref_img_avg_ch_" + chan);
            elseif mode == "Std. (full series)"
                data = m_read("ref_img_std_ch_" + chan);
            elseif mode == "Max (full series)"
                data = m_read("ref_img_max_ch_" + chan);
            else
                frame = m_read('current_frame');
                data = double(mat(:,:,frame));
            end
            
            % set image data:
            if isempty(obj.img)
                obj.img = imagesc(ax, "CData", data);
            else
                obj.img.CData = data;
            end
            colormap(obj.ax, cmap); % this has surprisingly good performance (:
            
            % apply range filter:
            high =  v_read("channel_high", 1);
            low = v_read("channel_low", 0);
            ch_max = max(data(:));
            ch_min = min(data(:));
            range = ch_max - ch_min;
            lims = [ch_min + (low*range), ch_min + (high*range)];
            if lims(1) >= lims(2)
                lims(2) = lims(2) + 1;
            end
            obj.ax.CLim = lims;
        end
        
        function img_out = spatially_smooth_img(obj,view,img)
                
            xy_smoothing = view.data.read("channel_xy_smoothing");
            if xy_smoothing > 0
                kernel = begonia.util.gausswin(xy_smoothing);
                kernel = kernel .* kernel';
                kernel = kernel / sum(kernel(:));
                
                img_out = convn(img,kernel,'same');
            else
                img_out = img;
            end
        end
        
        function data = get_range(obj, frame, mat, view)
            samples = view.data.read('channel_samples');
            
            start = frame - round(samples/2);
            end_ = frame + round(samples/2);
            if start < 1; start = 1; end
            if end_ > size(mat, 3); end_ = size(mat, 3); end
            
            data = mat(:,:,start:end_);
            %
        end
    end
    
end

