function updated = update_roi_table(roi_table)
    updated = roi_table;
    
    % append metadata field if missing:
    if ~ismember("metadata", roi_table.Properties.VariableNames)
        updated.metadata = repmat(struct(), size(roi_table.roi_id))
    end
end

