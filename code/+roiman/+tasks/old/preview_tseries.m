function vm = preview_tseries(ts, tools)
    if nargin < 2
        tools = true;
    end

    ch_mod = roiman.modules.Channel("Astrocyte (Ch2)", ch);
    vm = roiman.ViewManager(ts);
    vm.new_view("Channel " + ch, ch_mod);
    
    if tools
        vm.open_tool("manager", @roiman.tools.Manager);
        vm.open_tool("channel", @roiman.tools.Channel);
    end
end

