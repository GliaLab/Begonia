function add_ca_compartment(mtab, entities, category, tss, metric)
    import begonia.data_management.multitable.sources.CaCompartmentSource;
    
    n = length(entities);
    if n ~= length(tss); error("Must be as many datalocations as entity names");end

    if iscolumn(tss)
        tss = tss';
    end
    
    entity = entities';
    added = repmat(datetime(), n, 1);
    category = repmat(category, n, 1);
    source = arrayfun(@(ts) CaCompartmentSource(ts, metric), tss, 'UniformOutput', false);
    source = [source{:}]';
    mtab.data = [mtab.data ; table(entity, category, added, source)];
    
    mtab.register_column("ca_compartment", missing)
    mtab.register_column("ca_compartment_area_px2", missing)
end

