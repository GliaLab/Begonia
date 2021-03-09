function config_auto(tseries)
% This function calculates an estimate of the SNR of the recording and 
% applies filters in an attempt to reach a target SNR.
snr_threshold = 9;
snr_samples = 1000;

for ch = 1:tseries.channels
    mat = tseries.get_mat(ch);
    
    % Pick the last frames of the recording to estimate the SNR from. 
    en = size(mat,3);
    st = size(mat,3) - snr_samples + 1;
    st = max(1,st);
    mat_sub = mat(:,:,st:en);
    mat_sub = single(mat_sub);
    
    % Check SNR by first increasing the spatial smoothing and keeping the
    % temporal "smoothing" at 1 frame. 
    for xy = [0,1,2]
        
        snr = check_snr(mat_sub,xy);
        
        begonia.logging.log(1,'ch = %d, xy smoothing = %d, t smoothing = %d, estimated SNR = %g',ch,xy,1,snr);
        if snr >= snr_threshold
            break;
        end
    end
    
    if snr > snr_threshold
        % Keep parameters
        roa_pre_param(ch).channel = ch;
        roa_pre_param(ch).roa_enabled = true;
        roa_pre_param(ch).roa_t_smooth = 1;
        roa_pre_param(ch).roa_xy_smooth = xy;
        begonia.logging.log(1,'Keeping parameters for ch %d',ch);
        continue;
    end
    
    % Find a temporal smoothing fitting the snr threshold
    t_low = 1;
    t_high = 30;
    while true
        t = t_low + ceil((t_high - t_low) / 2);
        
        frame_start = size(mat,3) - snr_samples*t + 1;
        frame_start = max(1,frame_start);
        frame_end = size(mat,3);
        mat_sub = begonia.util.stepping_window(mat,t,t,[frame_start,frame_end],'single');
        
        snr = check_snr(mat_sub,xy);
        begonia.logging.log(1,'ch = %d, xy smoothing = %d, t smoothing = %d, estimated SNR = %g',ch,xy,t,snr);
        
        if t_low + 1 == t_high
            break
        elseif snr >= snr_threshold
            t_high = t;
        else
            t_low = t;
        end
    end
       
    % Keep parameters
    roa_pre_param(ch).channel = ch;
    roa_pre_param(ch).roa_enabled = true;
    roa_pre_param(ch).roa_t_smooth = t;
    roa_pre_param(ch).roa_xy_smooth = xy;
    begonia.logging.log(1,'Keeping parameters for ch %d',ch);
end

tseries.save_var(roa_pre_param);

begonia.logging.log(1,'Finished');

end

function snr = check_snr(mat,xy)
mat = single(mat);

if xy > 0
    spatial_kernel = begonia.util.gausswin(xy);
    spatial_kernel = spatial_kernel .* spatial_kernel';
    spatial_kernel = spatial_kernel ./ sum(spatial_kernel(:));
    spatial_kernel = single(spatial_kernel);
    mat = convn(mat,spatial_kernel,'same');
end

% Variance stabilization.
mat = sqrt(mat);

% Alternative standard deviation measurement.
std_v2 = @(x) sqrt(median(diff(x,1,3).^2,3)*1.1);

% Round so mode works. 
mat = round(mat,2);
img_mu = mode(mat,3);

% Noise
img_sigma = std_v2(mat);

% Pick a representative sigma value. 
sigma = nanmedian(img_sigma(:));

% Estimate snr. 
snr = nanmedian(img_mu(:)) / sigma;

end

