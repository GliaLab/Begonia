function plot_qa_rpa(tss)
    import begonia.util.*;

    for ts = to_loopable(tss)
        % extract and join all rois and signals:
        roi_table = ts.load_var("roi_table");

        dff = ts.load_var("roi_signals_dff", []);
        rpa_pct = ts.load_var("roi_signals_rpa");
        rois_dff = join(roi_table,dff);
        rpa_pct = join(rois_dff, rpa_pct);

        % find points to mark roi types on y-axis:
        rpa_pct = sortrows(rpa_pct, "type");
        types = unique(rpa_pct.type);
        type_start = arrayfun(@(tp) find(rpa_pct.type == tp, 1, 'first'), types);

        % plot figure:
        fig = figure("color", [0.84,0.90,0.95], "name", "RPA signal overview " + ts.name); 
        layout = tiledlayout(2, 1, "tilespacing", "compact");
        title(layout, ts.name);
        colormap(begonia.colormaps.magma);

        ax1 = nexttile();
        imagesc(vertcat(rpa_pct.signal_rpa_pct{:}) );
        title("RPA (fraction area active)"); xlabel("Frame (#)"); colorbar(); 
        yticks(type_start); yticklabels(types);
        
        ax2 = nexttile();
        if ~isempty(dff)
            imagesc(vertcat(rpa_pct.signal_dff{:}) );
            yticks(type_start); yticklabels(types);
        end
        title("Raw signal (df/f0)"); xlabel("Frame (#)"); colorbar(); 

    end
end

