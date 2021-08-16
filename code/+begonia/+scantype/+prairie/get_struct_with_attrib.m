function stru = get_struct_with_attrib(stru_list, at_name, at_value)
    
    for stru_cell = stru_list
        if iscell(stru_cell)
            stru = stru_cell{:};
        else
            stru = stru_cell;
        end
        if isfield(stru.Attributes, at_name) && stru.Attributes.(at_name) == at_value
            return
        end
    end
    
    stru = struct.empty;
end