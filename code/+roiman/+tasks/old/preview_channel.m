function vm = preview_channel(ts, ch)
    if nargin < 2
        ch = 1;
    end
    
    if isstring(ts)
        ts = begonia.scantype.find_scans(ts);
    end

    % create roi manager
    vm = roiman.ViewManager(ts);

    % view 1 : astrocyte channel:
    ch = roiman.modules.Channel("Astrocytes", ch);

    vm.new_view("new", "Channel 1 (Astrocytes)", ch);

    % add tools:
    vm.open_tool("manager", @roiman.tools.Manager);
    vm.open_tool("channel", @roiman.tools.Channel);
    vm.open_tool("guide", @roiman.tools.Guide);

    vm.run();
end

