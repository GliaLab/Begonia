function roi_signals_raw = extract_roi_signals(ts)
    import begonia.logging.log;
    import begonia.processing.roi.extract_single_roi_signal;

    roi_table = ts.load_var('roi_table');

    % Assume all cycles have equally many frames.
    signal = cell.empty;

    log(1, "Extracting roi signals: " + ts.path);

    cnt = 1;
    for ch = 1:ts.channels
        % Get the rois of the correct cycle and channel.
        ch_rows = roi_table(roi_table.channel == ch,:);

        % Get the matrix.
        mat = ts.get_mat(ch, 1);

        for i = 1:height(ch_rows)
            log(2, "RoI Ch" + ch + "/" + i);
            roi = table2struct(ch_rows(i, :));
            vec = extract_single_roi_signal(roi, mat);
            signal(cnt) = {vec};
            cnt = cnt + 1;
        end
    end

    roi_id = roi_table.roi_id;
    signal_raw = signal';
    roi_signals_raw = table(roi_id, signal_raw);
    
    ts.save_var("roi_signals_raw");
end

