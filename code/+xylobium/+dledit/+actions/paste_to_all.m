function paste_to_all(dlocs, model, editor)
import begonia.util.to_loopable;
 
if isempty(editor.clipboard_value)
    msgbox('Copy a value first');
    return;
end
 
for dloc = to_loopable(dlocs)
    for var = model.selected_vars
        cvar = char(var);
        if var == "roi_table"
            n_rois = height(editor.clipboard_value);
            uuids = string(begonia.util.make_uuids(n_rois));
            editor.clipboard_value.roi_id = uuids;
            source_id = repmat(string(dloc.name),n_rois,1);
            editor.clipboard_value.source_id = source_id;
        end
        model.save(dloc, cvar, editor.clipboard_value);
    end  
end
end
 
