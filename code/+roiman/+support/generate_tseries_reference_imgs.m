function generate_tseries_reference_imgs(vm)
    [m_has, m_write, m_read] = vm.data.shorts();
    
    tseries = m_read("tseries");

    w = waitbar(0, "Reference images");
    for chan = 1:tseries.channels
        waitbar((1 / tseries.channels) * chan ...
            , w ...
            , "Reference images for channel " + chan + ". Could take several minutes.");
        
        iavg = tseries.get_avg_img(chan);
        istd = tseries.get_std_img(chan);
        imax = tseries.get_max_img(chan);
        
        % reference images
        m_write("ref_img_avg_ch_" + chan,  iavg);
        m_write("ref_img_std_ch_" + chan,  istd);
        m_write("ref_img_max_ch_" + chan,  imax);
        
        tseries.save_var("img_avg_ch" + chan + "_cy1", iavg);
        tseries.save_var("img_std_ch" + chan + "_cy1", istd);
        tseries.save_var("img_max_ch" + chan + "_cy1", imax);
    end
    
    delete(w);
end

