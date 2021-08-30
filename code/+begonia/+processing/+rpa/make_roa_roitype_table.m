%{
make_roa_roitype_table 

Takes a roi list and a roa list from one or more tseries and correlates the
location of roa centeres with rois. The resulting table is written to the
tseries datalocation.
%}
function make_roa_roitype_table(tss, save)
    import begonia.util.to_loopable;
    
    if nargin < 2 
        save = true;
    end

    for ts = to_loopable(tss)

        begonia.logging.log(1, ts.name + " roi + roa table generating");
        
        if ~ts.has_var("roi_table") || ~ts.has_var("roa_table")
            error(ts.name + "needs both roi_table and roa_table variables")
        end

        roi_table = ts.load_var("roi_table");
        roa_table = ts.load_var("roa_table");

        r = 1;
        results = {};
        for chan = 1:ts.channels
            roi_tab_chan = roi_table(roi_table.channel == chan,:);
            if isempty(roi_tab_chan); continue; end

            for compartment = to_loopable(string(unique(roi_tab_chan.type)))
                roi_tab_comp = roi_tab_chan(roi_tab_chan.type == compartment,:);
                comp_mask = sum(cat(3, roi_tab_comp.mask{:}), 3);
                roa_x = roa_table.roa_center(:, 1);
                roa_y = roa_table.roa_center(:, 2);
                in_roi = arrayfun(@(x, y) comp_mask(y, x) == 1, roa_x, roa_y);

                comp_roas = roa_table(in_roi,:);
        %         figure(); imagesc(comp_mask); hold on;
        %         scatter(comp_roas.roa_center(:,1),  comp_roas.roa_center(:,2), 'x')
                sz = [height(comp_roas), 1];
                ts_name = repmat(categorical(string(ts.name)), sz);
                roa_id = comp_roas.roa_id;
                roi_type = repmat(compartment, sz);

                results(r) = {table(ts_name, roa_id, roi_type)};
                r = r + 1;
            end
        end

        roa_roitype_table = vertcat(results{:});

        if save
            ts.save_var(roa_roitype_table);
        end
    end
end

