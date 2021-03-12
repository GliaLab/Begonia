function add_memory(mtab, entities, category, trace, dt, start_abs)
    import begonia.data_management.multitable.sources.MemorySource;
    
    n = length(entities);
    if n ~= length(dt); error("Must be as many dt as entity names");end
    if n ~= length(start_abs); error("Must be as many start_abs as entity names");end
    
    entity = entities';
    added = repmat(datetime(), n, 1);
    category = repmat(category, n, 1);
    source = MemorySource(trace, dt, start_abs);
    
    mtab.data = [mtab.data ; table(entity, category, added, source)];
end

