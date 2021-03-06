function app = show(mat, show_tools, app)
    if nargin < 3
        app = roiman.App();
    end
    
    if nargin < 2
        show_tools = false;
    end
    
    ts = begonia.scantype.matlab.TSeriesMatrixAdapter(mat);

    if show_tools
        app.add_tool("manager", @roiman.tools.Manager);
        app.add_tool("channel", @roiman.tools.Channel);
    end
    vm = app.open(ts);

    ch_layer = roiman.modules.Channel("Matrix", 1);
    status_layer = roiman.modules.StatusOverlay("Status CH2");
    
    vm.new_view(ts.name, [ch_layer, status_layer]);
    
    if nargin < 3
        app.run();
    end
end

