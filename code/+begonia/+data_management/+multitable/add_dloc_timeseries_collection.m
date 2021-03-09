function add_dloc_timeseries_collection(mtab, entities, category, dlocs, varname, innervar)
    import begonia.data_management.multitable.sources.DataLocationSource;
    
    n = length(entities);
    if n ~= length(dlocs); error("Must be as many datalocations as entity names");end

    if iscolumn(dlocs)
        dlocs = dlocs';
    end
    
    entity = entities';
    added = repmat(datetime(), n, 1);
    category = repmat(category, n, 1);
    source = arrayfun(@(d) DataLocationSource(d, varname, "timeseriescollection", innervar), dlocs ...
        , 'UniformOutput', false);
    source = [source{:}]';
    mtab.data = [mtab.data ; table(entity, category, added, source)];
end

