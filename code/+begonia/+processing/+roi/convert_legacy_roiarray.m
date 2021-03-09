function roi_table = convert_legacy_roiarray(roi_array, ts_name)
    import begonia.logging.log;
    import begonia.processing.roi.make_roi_table;
    
    log(0, "Importing old rois");
    roi_table = make_roi_table();
    n = length(roi_array);
    
    for i = 1:n
        roi = roi_array(i);
        
        roi_table.short_name(i) = begonia.util.make_snowflake_id(roi.group);
        roi_table.source_id(i) = string(ts_name);
        roi_table.area_px2(i) = roi.area;
        roi_table.center_x(i) = roi.center(1);
        roi_table.center_y(i) = roi.center(2);
        roi_table.center_z(i) = 1;
        roi_table.translations(i) = {[]};
        roi_table.channel(i) = roi.channel;

        roi_table.mask(i) = {roi.mask};
        roi_table.roi_id(i) = roi.id;
        roi_table.roiarray_source(i) = {roi};
        roi_table.shape(i) = roi.shape;
        roi_table.tags(i) = "#legacy-import";
        roi_table.type(i) = roi.group;
        roi_table.version(i) = "1.0";
        roi_table.z_idx(i) = 1; % legacy had no depth concept, so we are at 1
        roi_table.added(i) = datetime();
        
        if ~isempty(roi.id_connected_roi)
            roi_table.parent_id(i) = string(roi.id_connected_roi);
        else
            roi_table.parent_id(i) = missing();
        end
    end
end

