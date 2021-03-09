function pre_process(ts,recording_folder)
if nargin < 2
    recording_folder = '';
end

roa_pre_param = ts.load_var('roa_pre_param');
roa_pre_param_hidden = ts.load_var('roa_pre_param_hidden',[]);
% Each struct in roa_pre_param belongs holds the parameters for each
% channel. 
for channel = 1:length(roa_pre_param)
    if channel > ts.channels
        warning("Pre-parameter is configured for more channels than exists in tseries - skipping channel" + channel)
        continue
    end
    
    % Check if the preprocessing has been run with the same parameters.
    if ~isempty(roa_pre_param_hidden) ...
            && isequal(roa_pre_param_hidden(channel),roa_pre_param(channel))
        begonia.logging.log(1,'ROA for channel %d has already been run with the same parameters, skipping.',channel);
        continue;
    end
    
    if ~roa_pre_param(channel).roa_enabled
        continue;
    end
    
    begonia.logging.log(1,'Running pre-processing for channel %d',channel);

    mat = ts.get_mat(channel);
    
    if roa_pre_param(channel).roa_t_smooth == 0
        roa_pre_param(channel).roa_t_smooth = 1;
    end
    
    %% Chunk columns of pixels to calculate baseline and sigma for large recordings. 
    
    % Define the spatial smoothing kernel. 
    filter_vec = begonia.util.gausswin(roa_pre_param(channel).roa_xy_smooth);
    filter_vec = filter_vec .* filter_vec';
    filter_vec = filter_vec ./ sum(filter_vec(:));
    filter_vec = single(filter_vec);

    % Alternative standard deviation measurement.
    std_alt = @(x) sqrt(median(diff(x,1,3).^2,3)/0.9099);
    
    roa_img_mu = zeros(ts.img_dim);
    roa_img_sigma = zeros(ts.img_dim);
    
    % Pad with half size of the kernel. 
    padding = (size(filter_vec,1) - 1 ) / 2;
    c = begonia.util.Chunker(mat,'chunk_padding',padding,'data_type','single','chunk_axis',2);
    for i = 1:c.chunks
        begonia.logging.log(1,'Processing step 1 chunk (%d/%d)',i,c.chunks);
        mat_sub = c.chunk(i);
    
        if roa_pre_param(channel).roa_t_smooth ~= 1
            mat_sub = begonia.util.stepping_window(mat_sub,roa_pre_param(channel).roa_t_smooth,[],[],'single');
        else
            mat_sub = single(mat_sub(:,:,:));
        end
        mat_sub = convn(mat_sub,filter_vec,'same');
        mat_sub = sqrt(mat_sub);
        mat_sub = round(mat_sub,2);
        mat_sub = c.unpad(mat_sub,i);
        
        I = c.chunk_indices_no_pad(i);
        roa_img_mu(I{:}) = mode(mat_sub,3);
        roa_img_sigma(I{:}) = std_alt(mat_sub);
    end

    sigma = median(roa_img_sigma(:));

    median_snr = median(roa_img_mu(:)) ./ sigma;
    
    %%
    % Detect ROA in chunks to save memory. 
    % Define the filter, this time temporal and spatial together. 
    filter_vec = begonia.util.gausswin(roa_pre_param(channel).roa_xy_smooth);
    filter_vec = filter_vec .* filter_vec' .* ones(1,1,roa_pre_param(channel).roa_t_smooth);
    filter_vec = filter_vec ./ sum(filter_vec(:));
    filter_vec = single(filter_vec);

    padding = ceil(roa_pre_param(channel).roa_t_smooth);
    c = begonia.util.Chunker(mat,'chunk_padding',padding,'data_type','single');

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
    begonia.path.make_dirs(roa_recording_file)

    if exist(roa_recording_file,'file')
        delete(roa_recording_file);
    end
    roa_recording = begonia.util.H5Array(roa_recording_file,size(mat),'single');

    for i = 1:c.chunks
        begonia.logging.log(1,'Processing step 2 chunk (%d/%d)',i,c.chunks);
        mat_sub = c.chunk(i);
        mat_sub = single(mat_sub);
        mat_sub = convn(mat_sub,filter_vec,'same');
        mat_sub = sqrt(mat_sub);
        mat_sub = c.unpad(mat_sub,i);

        I = c.chunk_indices_no_pad(i);
        roa_recording(I{:}) = single(mat_sub);
    end

    roa_img_mu_varname = sprintf('roa_img_mu_ch%d',channel);
    roa_img_sigma_varname = sprintf('roa_img_sigma_ch%d',channel);

    begonia.logging.log(1,'Saving ROA things');
    ts.save_var(roa_img_mu_varname,roa_img_mu);
    ts.save_var(roa_img_sigma_varname,roa_img_sigma);
    begonia.logging.log(1,'Finished Channel %d : Median SNR = %f',channel,median_snr);
end
ts.save_var('roa_pre_param_hidden',roa_pre_param);
end

