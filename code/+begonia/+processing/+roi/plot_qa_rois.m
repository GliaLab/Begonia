function fig = plot_qa_rois(tss, dff_lims)
    import begonia.util.*;

    for ts = to_loopable(tss)
        % get roi table:
        roi_table = ts.load_var("roi_table");
        types = string(unique(roi_table.type))
        
        % plot figure:
        fig = figure("color", [0.84,0.90,0.95], "name", "RoI overview " + ts.name); 
        layout = tiledlayout('flow', "tilespacing", "compact");
        title(layout, ts.name);
        
        axs = [];
        
        % plot channels:
        for ch = 1:ts.channels
            ax = nexttile();
            axs = [axs ax];
             
            mat_avg = ts.get_avg_img(ch, 1);
            imagesc(ax, mat_avg);
            title(ax, ts.channel_names(ch))
            colormap(ax, begonia.colormaps.turbo);
        end
        
        % plots rois:
        ax = nexttile();
        axs = [axs ax];
        total_mask = sum(cat(3, roi_table.mask{:}), 3) > 0;
        imagesc(total_mask);
        colormap(ax, 'bone');
        title(ax, "All RoIs n=" + height(roi_table));
        
        for type = to_loopable(types)
            ax = nexttile();
            axs = [axs ax];
            
            masks = roi_table.mask(roi_table.type == type);
            mask = sum(cat(3, masks{:}), 3) > 0;
            imagesc(mask);
            colormap(ax, 'bone');
            title(ax, type + " n=" + length(masks));
        end
        
        linkaxes(axs)
    end
end