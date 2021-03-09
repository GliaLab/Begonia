function make_reference_images(ts, ~, ~)

    for cy = ts.cycles
        for ch = 1:ts.channels
            begonia.logging.log(1, "Generating images for CH" + ch + "CY" + cy);
            ts.get_avg_img(ch, cy);
            ts.get_std_img(ch, cy);
            ts.get_max_img(ch, cy);
        end
    end
end

