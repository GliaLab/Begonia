function calculate_stats(ts)
if isempty(ts.dx)
    dx = nan;
else
    dx = ts.dx;
end
if isempty(ts.dy)
    dy = nan;
else
    dy = ts.dy;
end
if isempty(ts.dt)
    dt = nan;
else
    dt = ts.dt;
end

roa_param_hidden = ts.load_var('roa_param_hidden',[]);

if isempty(roa_param_hidden)
    return;
end

roa_traces = struct;
roa_tables = {};

for channel = 1:length(roa_param_hidden)
    if channel > ts.channels 
        warning("There are parameters for more channels than exists in tseries - skipping channel " + channel)
       continue; 
    end
    
    if ~roa_param_hidden(channel).roa_enabled
        continue;
    end
    
    begonia.logging.log(1,'Loading processed ROA for channel %d',channel);
    roa_mask = ts.load_var("roa_mask_ch"+channel);
    
    roa_ignore_mask = roa_param_hidden(channel).roa_ignore_mask;
    
    % Add the ignore border.
    roa_ignore_border = roa_param_hidden(channel).roa_ignore_border;
    roa_ignore_mask(1:roa_ignore_border,:) = true;
    roa_ignore_mask(end-roa_ignore_border+1:end,:) = true;
    roa_ignore_mask(:,1:roa_ignore_border) = true;
    roa_ignore_mask(:,end-roa_ignore_border+1:end) = true;
    
    % Flips it. Mask is true where ROAs are allowed.
    roa_ignore_mask = ~roa_ignore_mask;
    
    begonia.logging.log(1,'Calculating density trace');
    roa_density_trace = sum(sum(roa_mask,1),2)/sum(roa_ignore_mask(:));
    roa_density_trace = squeeze(roa_density_trace)';
    roa_density_trace = {roa_density_trace};

    begonia.logging.log(1,'Extracting events');
    roa_table = begonia.processing.roa.extract_roa_events(roa_mask,dx,dy,dt);

    roa_mask_area_pix = sum(roa_ignore_mask(:));
    roa_mask_area = roa_mask_area_pix * dx * dy;
    
    begonia.logging.log(1,'Calculating frequency trace');
    t = 0:size(roa_mask,3);
    roa_frequency_trace_count = histcounts(roa_table.roa_start_frame,t);
    roa_frequency_trace = roa_frequency_trace_count / dt / roa_mask_area;
    roa_frequency_trace_count = {roa_frequency_trace_count};
    roa_frequency_trace = {roa_frequency_trace};
    
    roa_traces(channel).uuid = categorical({ts.dl_unique_id});
    roa_traces(channel).channel = channel;
    roa_traces(channel).dt = dt;
    roa_traces(channel).dx = dx;
    roa_traces(channel).dy = dy;
    roa_traces(channel).roa_ignore_area_pix = roa_mask_area_pix;
    roa_traces(channel).roa_ignore_area = roa_mask_area;
    roa_traces(channel).roa_density_trace = roa_density_trace;
    roa_traces(channel).roa_frequency_trace = roa_frequency_trace;
    roa_traces(channel).roa_frequency_trace_count = roa_frequency_trace_count;
    
    roa_table.uuid(:) = categorical({ts.dl_unique_id});
    roa_table.channel(:) = channel;
    
    roa_tables{channel} = roa_table;
end

if isempty(roa_tables)
    return;
end

roa_traces = struct2table(roa_traces,'AsArray',true);
roa_table = cat(1,roa_tables{:});

begonia.logging.log(1,'Saving roa_traces');
ts.save_var(roa_table);
ts.save_var(roa_traces);

end

