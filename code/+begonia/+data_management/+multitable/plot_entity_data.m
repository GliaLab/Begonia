function figs = plot_entity_data(mtab, entities, timerange_s)
    import begonia.util.to_loopable;
    
    if ~isstring(entities) 
        warning("Entity list must be a list of one or more strings");
        entities = string(entities);
    end

    axs = [];
    annos = [];
    figs = [];
    ticks = round(linspace(1, timerange_s(2), 10));

    for entity = to_loopable(entities)
        traces = mtab.by_entity(entity);
        if isempty(traces)
            error("Entity does not exist in table: " + entity)
        end

        fig = figure("position", [0 0 600, 1000]);
        fig.Name = "Multitable data: " + entity;
        fig.Color = "white";
        figs = [figs fig]; %#ok<*AGROW>
        layout = tiledlayout(height(traces), 1, "TileSpacing", "Compact");
        title(layout, "Multitable data: " + entity);

        for r = 1:height(traces)
            entry = table2struct(traces(r,:));
            trace = entry.trace;
            t = (1:length(trace)) * entry.trace_dt;

            ax = nexttile();
            axs = [axs ax];

            plot(t, trace, "color", [.4 .4 .4], "LineWidth", 2);
            title_str = string(entry.category);
            
            % special override for common data type in begonia:
            if isfield(entry, "ca_compartment") & ~ ismissing(entry.ca_compartment)
                title_str = title_str + " / " + entry.ca_compartment;
            end
            
            a = annotation("textbox", ax.Position, ...
                "string", title_str, ...
                "linestyle", "none", ...
                "interpreter", "none", ...
                "color", "red");
            annos = [annos a];

            xticks(ticks);
%             xticks([]);
            xticklabels([])
            yticks([]);
            xlim(timerange_s);
            grid on;
            ax.Color = "#FFF7EB";
        end
        xticks(ticks);
        xticklabels(string(ticks))
        xlabel("Time (seconds)")
        
        for j = 1:length(axs)
            annos(j).Position = axs(j).Position;
        end
    end
end

