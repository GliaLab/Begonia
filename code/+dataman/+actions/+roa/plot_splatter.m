function plot_splatter(ts, model, editor)
    def_conf = struct();
    
    def_conf.start_f = 1;
    def_conf.end_f = ts.frame_count;
    def_conf.ds_x = 5;
    def_conf.ds_y = 5;
    def_conf.ds_z = 50;

    c = ts.load_var("splatter_config", def_conf);
    
    % downsample and plot each channel:
    for chan_idx = 1:ts.channels
        chan = "ch" + chan_idx;
        mask_var = "roa_mask_" + chan;
        if ~ts.has_var(mask_var); continue; end
        
        mask = ts.load_var(mask_var);
        x_range = 1:c.ds_x:ts.img_dim(1);
        y_range = 1:c.ds_y:ts.img_dim(2);
        z_range = c.start_f:c.ds_z:c.end_f;
        
        mask_ds = mask(x_range, y_range, z_range);
        f = begonia.processing.roa.plot_roa_3d(...
            mask_ds, ...
            ts.dx * c.ds_x, ...
            ts.dy * c.ds_y, ...
            ts.dt * c.ds_z);
        
        ax = f.CurrentAxes;
        title(ax, ts.name + " / " + upper(chan))
    end
    
    warning("Splatter from GUI uses low sampling by default. You may want to use the processing.roa.plot_roa_3d() method programatically.")

end

