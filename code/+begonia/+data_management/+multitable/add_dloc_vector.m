function add_dloc_vec(mtab, entities, category, dlocs, varname, dt)
    import begonia.data_management.multitable.sources.DataLocationSource;
    
    n = length(entities);
    if n ~= length(dlocs); error("Must be as many datalocations as entity names");end
    if n ~= length(dt)
        if length(dt) == 1
            dt = repmat(dt, size(entities));
        else
            error("Must be as many dt as entity names, or one if all are the same");
        end
    end
    
    if iscolumn(dlocs)
        dlocs = dlocs';
    end
    
    entity = entities';
    added = repmat(datetime(), n, 1);
    category = repmat(category, n, 1);
    source = arrayfun(@(d) DataLocationSource(d, varname, "var", []), dlocs ...
        , 'UniformOutput', false);
    source = [source{:}]';
    
    % assign hardcoded dt:
    for i = 1:length(source)
        source(i).dt = dt(i);
    end
    
    mtab.data = [mtab.data ; table(entity, category, added, source)];
end

