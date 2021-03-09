function mark_rois(ts, model, editor)
    app = dataman.support.get_roiman_instance(editor);
    
    % create a new view for editing rois on this tseries:
    vm = app.open(ts);

    roiman.initializers.init_roi_editing(vm);

    ch2 = roiman.modules.Channel("Channel view", 1);
    status = roiman.modules.StatusOverlay("Status overlay");
    rois = roiman.modules.Rois("RoIs", 1);
    roipaint = roiman.modules.RoIPaintOverlay("RoI Paint Overlay");

    % sets up initial roi editing values
    vm.add_mode(roiman.modes.RoIPaint()); % rp - roi painting
    vm.add_mode(roiman.modes.RoISelect()); % rs - selection and grouping 
    
    vm.new_view(ts.name, [ch2, status rois roipaint]);
end

