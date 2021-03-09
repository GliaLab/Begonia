% sets up a new roi table:
function roi_table = make_roi_table()
    % set up the roi table:
    short_name = string.empty;
    source_id = string.empty;
    roi_id = string.empty;
    channel = [];
    z_idx = [];
    shape = string.empty;
    type = string.empty;
    parent_id = string.empty;
    tags = string.empty;
    area_px2 = [];
    center_x = [];
    center_y = [];
    center_z = [];
    translations = cell.empty; % translations in time and space
    mask = cell.empty;
    roiarray_source = cell.empty;
    version = string.empty;
    added = datetime.empty;
    
    roi_table = table(short_name, roi_id, source_id, channel, z_idx, shape, type, parent_id, ...
        area_px2, center_x, center_y, center_z, translations, mask, roiarray_source, version, tags, added);
end

