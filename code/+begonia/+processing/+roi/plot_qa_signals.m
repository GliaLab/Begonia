function fig = plot_qa_signals(tss, dff_lims)
    import begonia.util.*;

    for ts = to_loopable(tss)
        % extract and join all rois and signals:
        roi_table = ts.load_var("roi_table");

        signal = ts.load_var("roi_signals_raw");
        signal_dff = ts.load_var("roi_signals_dff");
        signal_doughnut = ts.load_var("roi_signals_doughnut");

        rois = join(roi_table, signal);
        rois = join(rois, signal_dff);
        rois = join(rois, signal_doughnut);

        rois = sortrows(rois, "type");

        types = unique(rois.type);
        type_start = arrayfun(@(tp) find(rois.type == tp, 1, 'first'), types);

        % plot figure:
        fig = figure("color", [0.84,0.90,0.95], "name", "Signal overview " + ts.name); 
        layout = tiledlayout(3, 1, "tilespacing", "compact");
        title(layout, ts.name);
        colormap(begonia.colormaps.magma);

        ax1 = nexttile();
        imagesc(vertcat(rois.signal_raw{:}));
        title("Raw (A.U.)"); xlabel("Frame (#)"); colorbar(); 
        yticks(type_start); yticklabels(types);

        ax2 = nexttile();
        imagesc(vertcat(rois.signal_dff{:}));
        title("Normalized (df/f0)"); xlabel("Frame (#)"); colorbar(); 
        if nargin > 1
            caxis(dff_lims);
        end
        yticks(type_start); yticklabels(types);

        ax3 = nexttile();
        imagesc(vertcat(rois.signal_doughnut{:}));
        title("Doughnut signals"); xlabel("Frame (#)"); colorbar();
        yticks(type_start); yticklabels(types);

        linkaxes([ax1, ax2, ax3])
    end
end

