function app = get_roiman_instance(editor)
    if isempty(editor.roiman) || ~isvalid(editor.roiman)
        app = roiman.App();
        editor.roiman = app;
        app.add_tool("manager", @roiman.tools.Manager);
        app.add_tool("channel", @roiman.tools.Channel);
        app.add_tool("guide", @roiman.tools.Guide);
        app.add_tool("rois", @roiman.tools.RoIs);
        app.add_tool("roa", @roiman.tools.RoaThreshold);
        app.add_tool("roa_pre", @roiman.tools.RoaPre);
        app.add_tool("roa_plot", @roiman.tools.RoaPlot);
        app.run();
        editor.roiman = app;
    else
        app = editor.roiman;
    end 
end

