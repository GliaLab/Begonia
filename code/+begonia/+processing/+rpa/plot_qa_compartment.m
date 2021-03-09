function fig = plot_qa_compartment(ts)
    if ~ts.has_var("compartment_signal")
        error("No RPA compartment signal found - need to process?");
    end

    compartment_signal = ts.load_var("compartment_signal");
    
    % ommit channels on skip list:
    skip_list = ts.load_var("compartment_signal_skip", string.empty);
    comp_name = string(compartment_signal.compartment) + " CH" + compartment_signal.channel;
    compartment_signal = compartment_signal(~contains(comp_name, skip_list),:);
    
    fig = figure("Name", ts.name + " compartment activity", "color", [0.84,0.90,0.95], "position", [100 100 1000,2000]);
    layout = tiledlayout(5, 1);
    title(layout, ts.name + " compartment activity");

    % active fraction:
    nexttile();
    plot_metric(compartment_signal, "active_fraction", ...
        "Active fraction", "Fraction", "Frame (#)", skip_list, 0.5);
    
    % new events
    nexttile();
    plot_metric(compartment_signal, "new_events", ...
        "New events", "#", "Frame (#)", skip_list);
    
    % active event count 
    nexttile();
    plot_metric(compartment_signal, "active_event_count", ...
        "Ongoing events", "#", "Frame (#)", skip_list);

    % active event count 
    nexttile();
    plot_metric(compartment_signal, "active_area_count", ...
        "Active separat areas", "#", "Frame (#)", skip_list);
    
    % active event count 
    nexttile();
    plot_metric(compartment_signal, "new_event_duration", ...
        "Duration of new events ", "Duration (frames)", "Frame (#)", skip_list);
end


function plot_metric(compartment_signal, varname, title_str, y_str, x_str, skip_list, offset)
    if nargin < 7
        points = cat(1, compartment_signal.(varname){:});
        points = points(points ~= 0);
        offset = max(points(:)) / 2;
    end

    for r = 1:height(compartment_signal)
        ev_cnts = compartment_signal.(varname){r};
        plot(ev_cnts + (r * offset)); hold on;
    end

    legend_str = string(compartment_signal.compartment) + " CH" + compartment_signal.channel;
    legend(legend_str, "location", "northeastoutside")
    title(title_str); ylabel(y_str); xlabel(x_str);
    yticks([]);
end

