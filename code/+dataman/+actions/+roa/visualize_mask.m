function visualize_mask(ts, model, editor)
    import begonia.scantype.matlab.TSeriesMatrixAdapter;

    app = dataman.support.get_roiman_instance(editor);
    for ch = 1:ts.channels 
        mask_var = "roa_mask_ch" + ch;
        if ts.has_var(mask_var)
            
            % get the mask matrix:
            mask = ts.load_var(mask_var);
            ts_virt = TSeriesMatrixAdapter(mask, ts);
            
            % open in roimanager with a simple overlay:
            vm = app.open(ts_virt);
            roiman.initializers.init_roi_editing(vm);
            
            ch_layer = roiman.modules.Channel("RoA mask", 1);
            rois = roiman.modules.Rois("RoIs", 1);
            status_layer = roiman.modules.StatusOverlay("Status CH2");
            layers = [ch_layer, rois, status_layer];
            
            vm.new_view(ts.name + " RoA mask CH" + ch, layers);
        end

%         mask_file = fullfile(ts.path, "roa_mask_ch" + ch + ".h5");
%         if exist(mask_file, "file")
%             
%             % get the mask matrix:
%             mask = begonia.util.H5Array(mask_file);
%             ts_virt = TSeriesMatrixAdapter(mask, ts);
%             
%             % open in roimanager with a simple overlay:
%             vm = app.open(ts_virt);
%             
%             ch_layer = roiman.modules.Channel("RoA mask", 1);
%             status_layer = roiman.modules.StatusOverlay("Status CH2");
%             vm.new_view(ts.name + " RoA mask", [ch_layer, status_layer]);
%         end
    end
end

