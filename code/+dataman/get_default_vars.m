function vars = get_default_vars(vars)
    if nargin < 1
       vars = string.empty; 
    end

    vars = [vars, "name", "!tags", "path", "type", "source", "stabilized", ...
        "roi_table", "roi_status", "roa_status", "roa_template", "roa_mask", ...
        "roi_signals_dff", "roi_signals_rpa", ...
        "roa_pre_param","roa_pre_finished", "roa_param","roa_finished"];
end

