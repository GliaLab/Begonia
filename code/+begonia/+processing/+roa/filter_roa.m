function filter_roa(ts,recording_folder)
if nargin < 2
    recording_folder = '';
end

roa_param = ts.load_var('roa_param',[]);
roa_pre_param = ts.load_var('roa_pre_param_hidden',[]);
if isempty(roa_param) && ~isempty(roa_pre_param)
    begonia.logging.log(1,'Missing pre-parameters, generating default parameters');
    
    roa_param = roa_pre_param;
    roa_param.roa_threshold = 4;
    roa_param.roa_min_size = 0;
    roa_param.roa_min_duration = 0;
    roa_param.roa_ignore_mask = false(ts.img_dim);
    roa_param.roa_ignore_border = 0;
    ts.save_var(roa_param);
    
elseif isempty(roa_param)
    begonia.logging.log(1,'Missing parameters, skippinig');
    error("No RoA parameters set.");
    return;
end

roa_param_hidden = ts.load_var('roa_param_hidden',[]);

for channel = 1:ts.channels
    if channel <= length(roa_param) && roa_param(channel).roa_enabled
        ts.clear_var("roa_mask_ch" + channel);
    else
        continue;
    end
    
    if ~isempty(roa_param_hidden) && isequal(roa_param_hidden(channel),roa_param(channel))
        begonia.logging.log(1,'ROA for channel %d has already been run with the same parameters, skipping.',channel);
        continue;
    end
    
    begonia.logging.log(1,'Processing ROA : Channel %d',channel);
    
    % Get the pre-processed recording
    if isempty(recording_folder)
        roa_recording_file = sprintf('roa_recording_ch%d.h5',channel);
        if isfolder(ts.path)
            roa_recording_file = fullfile(ts.path,roa_recording_file);
        else
            [p,f] = fileparts(ts.path);
            roa_recording_file = fullfile(p,[f,'.metadata'],roa_recording_file);
        end
    else
        roa_recording_file = sprintf('roa_recording_ch%d_%s.h5',channel,ts.dl_unique_id);
        roa_recording_file = fullfile(recording_folder,roa_recording_file);
    end
    roa_recording = begonia.util.H5Array(roa_recording_file);

    % Threshold the recording
    roa_img_mu_varname = sprintf('roa_img_mu_ch%d',channel);
    roa_img_mu = ts.load_var(roa_img_mu_varname);
    
    roa_img_sigma_varname = sprintf('roa_img_sigma_ch%d',channel);
    roa_img_sigma = ts.load_var(roa_img_sigma_varname);
    sigma = median(roa_img_sigma(:));
    c = begonia.util.Chunker(roa_recording);
    roa_mask = false(size(roa_recording));
    for i = 1:c.chunks
        begonia.logging.log(1,'Thresholding chunk (%d/%d)',i,c.chunks);
        I = c.chunk_indices(i);
        roa_mask(I{:}) = c.chunk(i) > roa_img_mu + roa_param(channel).roa_threshold * sigma;
    end
    
    % Add the ignore border.
    roa_ignore_mask = roa_param(channel).roa_ignore_mask;
    roa_ignore_border = roa_param(channel).roa_ignore_border;

    roa_ignore_mask(1:roa_ignore_border,:) = true;
    roa_ignore_mask(end-roa_ignore_border+1:end,:) = true;
    roa_ignore_mask(:,1:roa_ignore_border) = true;
    roa_ignore_mask(:,end-roa_ignore_border+1:end) = true;
    
    % Remove ignored areas.
    roa_mask = roa_mask & ~roa_ignore_mask;

    % Filter ROA
    begonia.logging.log(1,'Filtering small ROA');
    roa_mask = begonia.processing.roa.remove_small_events(roa_mask,roa_param(channel).roa_min_size);
    begonia.logging.log(1,'Filtering short ROA');
    roa_mask = begonia.processing.roa.remove_short_events(roa_mask,roa_param(channel).roa_min_duration);

    begonia.logging.log(1,'Saving processed ROA');
    ts.save_var("roa_mask_ch" + channel, roa_mask);
    ts.save_var("roa_ignore_mask_ch" + channel, roa_ignore_mask);
end

ts.save_var('roa_param_hidden',roa_param);

begonia.processing.roa.calculate_stats(ts);
end

