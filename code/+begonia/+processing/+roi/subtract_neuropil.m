function Ns_subtracted = subtract_neuropil(ts)

% Load rois
roi_table = ts.load_var("roi_table");
signal = ts.load_var("roi_signals_raw");
signal_dff = ts.load_var("roi_signals_dff");
signal_doughnut = ts.load_var("roi_signals_doughnut");

rois = join(roi_table, signal);
rois = join(rois, signal_dff);
rois = join(rois, signal_doughnut);

% Get neuron rois
neu_idx = rois.type == "NS";
roi_neurons = rois(neu_idx,:);
roi_neurons_signal = roi_neurons.signal_raw;
ca_signal_doughnuts = roi_neurons.signal_doughnut;
f0 = roi_neurons.f0;
%%  Subtract doughnut signal from Ns rois

Ns_subtract = cell(size(roi_neurons_signal));
for i = 1:height(roi_neurons)
    y = roi_neurons_signal{i}';
    X = ca_signal_doughnuts{i}';
    
    b = (X'*X)\(X'*y);
    y_hat = X * b;
    trace = (y - y_hat)/f0(i);
    
    Ns_subtract{i} = trace';
end

% 
roi_id = roi_table.roi_id;
Ns_subtracted = repmat({nan(1, ts.frame_count)}, height(roi_table), 1);
Ns_subtracted(neu_idx) =  Ns_subtract;
signal_subtracted_dff = Ns_subtracted;
roi_signals_subtracted = table(roi_id,signal_subtracted_dff);
ts.save_var('roi_signals_dff_subtracted',roi_signals_subtracted)

end