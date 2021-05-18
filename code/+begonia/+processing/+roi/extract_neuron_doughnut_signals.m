function roi_table = extract_neuron_doughnut_signals(ts)
    import begonia.processing.roi.extract_single_roi_signal;

    roi_table = ts.load_var("roi_table");
    
    mask_dough = cell.empty;
    signal_dough = cell.empty;
    
    % pick out neuron rois. 
    neu_idx = roi_table.type == "NS";
    roi_neurons = table2struct(roi_table(neu_idx,:));

    r_outer = ceil(7/ts.dx);
    r_inner = ceil(2/ts.dx);

    se_outer = strel('sphere', r_outer);
    se_inner = strel('sphere', r_inner);

    for i = 1:length(roi_neurons)
        % remove doughnut areas overlapping with other neurons by merging
        % their masks and later removing that from the doughnut mask:
        other_idxs = [roi_neurons.roi_id] ~= roi_neurons(i).roi_id;
        other_neurons = roi_neurons(other_idxs);
        merged_mask = sum(cat(3, other_neurons.mask), 3) > 0;
        merged_mask = imdilate(merged_mask,se_inner);
        
%         merged_roi = roi_neurons([roi_neurons ~= roi_neurons(i)]).merge();
%         merged_mask = merged_roi.mask;
%         merged_mask = imdilate(merged_mask,se_inner);

        roi = roi_neurons(i);

        % create doughnut mask:
        mask = roi.mask;
        mask_out = imdilate(mask, se_outer);
        mask_in = imdilate(mask, se_inner);
        mask = xor(mask_out,mask_in);
        mask = mask - (mask & merged_mask);

        mask_dough(i) = {mask};
    end
    
    % add doughnut mask to rois:
    roi_table.mask_doughnut(neu_idx) = mask_dough;

    % extract signals, and make sure to use correct channel:
    chans = unique(roi_table.channel)';
    for ch = chans
        mat = ts.get_mat(ch, 1);
        for i = 1:length(roi_neurons)
            roi = roi_neurons(i);
            mask = mask_dough{i};
            if ~(roi.channel == ch && roi.type == "NS"); continue; end
            signal_dough(i) = {extract_single_roi_signal(roi, mat, mask)};
        end
    end
    
    roi_id = roi_table.roi_id;
    signal_doughnut = repmat({nan(1, ts.frame_count)}, height(roi_table), 1);
    signal_doughnut(neu_idx) = signal_dough;

    roi_signals_doughnut = table(roi_id, signal_doughnut);
    ts.save_var("roi_signals_doughnut");
end

