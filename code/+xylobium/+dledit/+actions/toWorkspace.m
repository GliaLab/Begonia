function toWorkspace( dlocs, model, editor)
%TOWORKSPACE Summary of this function goes here
%   Detailed explanation goes here
    disp('TO WORKSPACE')
    
    data = struct;
    data.selected = dlocs';
    data.value = model.selected_values;
    data.all = model.dlocs';
    data.vars = model.selected_vars;
    data.timestamp = datetime;
    
    assignin('base','eddata',data);
    data.value
    disp('Variable "eddata" set');
end

