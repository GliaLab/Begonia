function gui_adjust_threshold(ts,roa_recording_folder, editor)
if nargin < 2
    roa_recording_folder = [];
end
if nargin < 3
    editor = [];
end

if length(ts) > 1
    begonia.logging.log(1,'Multiple TSeries selected, only opening the tool for the first TSeries.')
    ts = ts(1);
end

roa_pre_param = ts.load_var('roa_pre_param',[]);
roa_pre_param_hidden = ts.load_var('roa_pre_param_hidden',[]);
if isempty(roa_pre_param) || ~isequal(roa_pre_param,roa_pre_param_hidden)
    begonia.logging.log(1,'Pre-processing have not been completed, cannot configure parameters.');
    return;
end

app = dataman.support.get_roiman_instance(editor);

vm = app.open(ts);
vm.data.write("editor",editor);

roiman.initializers.init_roa(vm,roa_recording_folder);

vm.add_mode(roiman.modes.RoaIgnore());

ch = roiman.modules.Channel("Channel",1);
roa = roiman.modules.RoaOverlay("ROA");
roa_ignore = roiman.modules.RoaIgnoreOverlay("ROA Ignore");
status = roiman.modules.StatusOverlay("Status");

vm.new_view(ts.name, [ch,roa,roa_ignore,status]);

end

