% this sets up the editing environment for roi editing:
function init_roi_editing(manager)
    import begonia.processing.roi.convert_legacy_roiarray;
    import begonia.processing.roi.make_roi_table;
    
    [~, m_write, m_read] = manager.data.shorts();
    
    type = ["AS", "AP", "Gp", "AE", "Cap", "NS", "Np", "ND", "NA"]';
    desc = ["Astro. somata", "Astro. process", "Gliopil", "Astro. endfeet", "Astro. capillary", "Neu. somata", "Neuropil", "Neu. dendrite", "Neu. axon"]';

    m_write("roiedit_roi_types_available", table(type, desc));
    m_write("roiedit_roi_type", "AS");
    
    % start with no rois selected:
    m_write("roiedit_selected", "");
    
    m_write("roipaint_operation", "add");
    
    % read existing table or convert legacy roiarray if present:
    ts = m_read("tseries");
    if ts.has_var("roi_table") 
        roi_table = ts.load_var('roi_table');
    elseif ts.has_var('roi_array')
        roi_table = convert_legacy_roiarray(ts.load_var('roi_array'), ts.name);
        ts.save_var('roi_table');
    else
        roi_table = make_roi_table(); % fresh beginnings (:
    end
    
    % ensure up-to-date
    roi_table = begonia.processing.roi.update_roi_table(roi_table); 
    m_write("roi_table", roi_table);
end



