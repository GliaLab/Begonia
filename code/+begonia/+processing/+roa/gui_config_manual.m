function gui_config_manual(ts, model, editor)

if length(ts) > 1
    begonia.logging.log(1,'Multiple TSeries selected, only opening the tool for the first TSeries.')
    ts = ts(1);
end

app = dataman.support.get_roiman_instance(editor);

vm = app.open(ts);

roiman.initializers.init_roa_pre(vm);
ch = roiman.modules.Channel("Channel",1);
status = roiman.modules.StatusOverlay("Status");

vm.new_view(ts.name, [ch,status]);
end
