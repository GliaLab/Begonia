function reread_xml_metadata(tseries)

    for ts = begonia.util.to_loopable(tseries)
        if ~isa(ts, "begonia.scantype.h5_old.TSeriesH5Old")
            error("TSeries must be H5Old format for this method to work")
        end
        
        xml_file = fullfile(ts.path, ts.name + ".xml");
        metadata = begonia.scantype.prairie.read_metadata(xml_file);

        ts.channel_names        = metadata.channel_names;
        ts.channels             = metadata.channels;
        ts.dt                   = metadata.dt(1);
        ts.dx                   = metadata.dx;
        ts.dy                   = metadata.dx;
        ts.cycles               = metadata.cycles;
        ts.zoom                 = metadata.optical_zoom;
        ts.frame_count          = metadata.frames_in_cycle;
        ts.frame_position_um    = metadata.frame_position_um;
    end
end

