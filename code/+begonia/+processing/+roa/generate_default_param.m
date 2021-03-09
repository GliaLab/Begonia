function roa_param = generate_default_param(ts,return_pre_param,use_pre_param)
if nargin < 2
    return_pre_param = false;
end
if nargin < 3
    use_pre_param = false;
end

if use_pre_param
    roa_param = ts.load_var('roa_pre_param',struct);
else
    roa_param = struct;
end

for ch = 1:ts.channels
    roa_param(ch).channel = ch;
    roa_param(ch).roa_enabled = true;
    roa_param(ch).roa_t_smooth = 0;
    roa_param(ch).roa_xy_smooth = 0;
    
    if return_pre_param
        continue
    end
    
    roa_param(ch).roa_threshold = 4;
    roa_param(ch).roa_min_size = 0;
    roa_param(ch).roa_min_duration = 0;
    roa_param(ch).roa_ignore_mask = false(ts.img_dim);
    roa_param(ch).roa_ignore_border = 0;
end


end

