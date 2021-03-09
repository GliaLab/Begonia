function convert_legacy(ts, model, editor)
    import begonia.processing.roi.convert_legacy_roiarray;

    if ts.has_var("roi_array")
        roi_array = ts.load_var("roi_array");
        roi_table = convert_legacy_roiarray(roi_array, ts.name);
        ts.save_var(roi_table)
    end
end

