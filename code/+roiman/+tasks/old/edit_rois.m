function edit_rois(ts, debug)
    
    if nargin < 2
        debug = false;
    end

    if nargin < 1
        ts = begonia.scantype.find_scans(uigetdir);
        ts = ts(1);
    end

    % create roi manager
    app = roiman.App();
    app.add_tool("manager", @roiman.tools.Manager);
    app.add_tool("channel", @roiman.tools.Channel);
    app.add_tool("guide", @roiman.tools.Guide);
    app.add_tool("rois", @roiman.tools.RoIs);
    
    if debug
        app.run_debug();
    else 
        app.run()
    end
        
    vm = roiman.ViewManager(ts, app);

    % install modes for roi editing - modes must be installed before views are
    % created to ensure they get a chance to add required data:
    roiman.initializers.init_roi_editing(vm); % sets up initial roi editing values
    vm.add_mode(roiman.modes.RoIPaint()); % rp - roi painting
    vm.add_mode(roiman.modes.RoISelect()); % rs - selection and grouping 

    % view 1 : astrocyte channel:
    ch2 = roiman.modules.Channel("Astrocytes", 1);
    rois = roiman.modules.Rois("RoIs (channel 2)", 1);
    roipaint = roiman.modules.RoIPaintOverlay("RoI Paint Overlay");
    status = roiman.modules.StatusOverlay("Status CH2");

    vm.new_view("Channel 1 (Astrocytes)", [ch2, rois roipaint status]);
end
