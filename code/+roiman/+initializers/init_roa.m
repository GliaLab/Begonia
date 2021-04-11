function init_roa(manager,roa_recording_folder)
if nargin < 2
    roa_recording_folder = [];
end
[m_has, m_write, m_read] = manager.data.shorts();

ts = m_read("tseries");

% Create default param or load parameters.
if ts.has_var('roa_param')
    roa_param = ts.load_var('roa_param');
    roa_param_saved = roa_param;
else
    roa_param = struct;
    for chan = 1:ts.channels
        roa_param(chan).roa_threshold = 4;
        roa_param(chan).roa_min_size = 1;
        roa_param(chan).roa_min_duration = 1;
        roa_param(chan).roa_ignore_mask = false(ts.img_dim);
        roa_param(chan).roa_ignore_border = 0;
    end
    
    roa_param_saved = [];
end

% Copy over pre-processing parameters to the parameters that are stored in
% the GUI. 
roa_pre_param = ts.load_var('roa_pre_param_hidden');
f = fieldnames(roa_pre_param);
for ch = 1:ts.channels
    for i = 1:length(f)
        roa_param(ch).(f{i}) = roa_pre_param(ch).(f{i});
    end
end

m_write("roa_param",roa_param);
m_write("roa_param_saved",roa_param_saved);

% Load the processed roa param if they exist. 
roa_param_processed = ts.load_var("roa_param_hidden",[]);
m_write("roa_param_processed",roa_param_processed);

% Load roa traces if they exist.
roa_traces = ts.load_var('roa_traces',[]);
m_write("roa_traces",roa_traces);

for chan = 1:ts.channels
    
    roa_img_mu_varname = sprintf('roa_img_mu_ch%d',chan);
    roa_img_mu = ts.load_var(roa_img_mu_varname,[]);
    m_write("roa_img_mu_ch"+chan,roa_img_mu);
    
    roa_img_sigma_varname = sprintf('roa_img_sigma_ch%d',chan);
    roa_img_sigma = ts.load_var(roa_img_sigma_varname,[]);
    m_write("roa_img_sigma_ch"+chan, roa_img_sigma);
    
    roa_mask = ts.load_var("roa_mask_ch"+chan,[]);
    m_write("roa_mask_ch"+chan,roa_mask);

    % Load the pre-processed recording. 
    if ~isempty(roa_recording_folder)
        roa_recording_file = sprintf('roa_recording_ch%d_%s.h5',chan,ts.dl_unique_id);
        roa_recording_file = fullfile(roa_recording_folder,roa_recording_file);
    else
        roa_recording_file = sprintf('roa_recording_ch%d.h5',chan);
        if isfolder(ts.path)
            roa_recording_file = fullfile(ts.path,roa_recording_file);
        else
            [p,f] = fileparts(ts.path);
            roa_recording_file = fullfile(p,[f,'.metadata'],roa_recording_file);
        end
    end
    if isfile(roa_recording_file)
        roa_recording = begonia.util.H5Array(roa_recording_file);
    else
        roa_recording = [];
    end
    m_write("roa_recording_ch"+chan,roa_recording);
end


end

