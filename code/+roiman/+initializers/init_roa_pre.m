function init_roa_pre(manager)
[~, m_write, m_read] = manager.data.shorts();

ts = m_read("tseries");

% Create default param or load parameters.
if ts.has_var('roa_pre_param')
    roa_pre_param = ts.load_var('roa_pre_param');
    roa_pre_param_saved = roa_pre_param;
else
    % Make some default parameters
    roa_pre_param = struct;
    for channel = 1:ts.channels
        roa_pre_param(channel).channel = channel;
        roa_pre_param(channel).roa_enabled = false;
        roa_pre_param(channel).roa_t_smooth = 1;
        roa_pre_param(channel).roa_xy_smooth = 1;
    end
    
    % By default only enable processing on the first channel.
    roa_pre_param(1).roa_enabled = true;
    
    roa_pre_param_saved = [];
end
m_write("roa_pre_param",roa_pre_param);
m_write("roa_pre_param_saved",roa_pre_param_saved);

end

