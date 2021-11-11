function ts_out = run_normcorre(ts, output_path, options, output_format, use_memmap, lift_to_zero)

if nargin < 6
    lift_to_zero = true;
end

if nargin < 5
    use_memmap = false;
end

alignment_channel = options.channel;

nc_params = options.nc_params;
% Set the output type to H5 as this function is ment to run lazily.
nc_params.output_type = 'h5';
% Specify where the temporary data from normcore will be saved. 
nc_params.h5_filename = sprintf('motion_corrected_ch%d.h5',alignment_channel);

% Fool NoRMCorre to read data lazily by mimmicking memmap. NoRMCorre
% assumes the output from memmap is single. 
mat = ts.get_mat(alignment_channel);

if use_memmap
    obj = begonia.processing.motion_correction.DummyMemmap();
    obj.Y = mat;
    
    if lift_to_zero
        warning("cannot lift values to zero as lowest when using memory map");
    end
else
    % read all data into memory:
    obj = mat(:,:,:);
    
    % normcorre does not like negative values, so we lift to zero if
    % needed by subtracting the lowest value if less than zero:
    if lift_to_zero
        low = min(obj(:));
        if low < 0
            warning("your matrix has negative values – all values will be shifted to ensure normocorre operates well on the data");
            obj = obj - low;
        end
    end
end
mat_out = {};

% Delete the output files from NoRMCorre if they are left over from a 
% previous run.
for ch = 1:ts.channels
    motcor_filename = sprintf('motion_corrected_ch%d.h5',ch);
    if exist(motcor_filename,'file')
        delete(motcor_filename);
    end
end

% Supress warnings when writing single to uint16 in hdf5. 
warning off
[mat_out{alignment_channel},shifts,template,nc_params] = normcorre(obj,nc_params);
warning on

% Align the other channels based on the alignment channel. 
channels = 1:ts.channels;
channels(alignment_channel) = [];
for ch = channels
    begonia.logging.log(1,'Shifting channel %d',ch);
    nc_params.h5_filename = sprintf('motion_corrected_ch%d.h5',ch);
    
    mat = ts.get_mat(ch);
    obj = begonia.processing.motion_correction.DummyMemmap();
    obj.Y = mat;
    
    % Supress warnings when writing single to uint16 in hdf5. 
    warning off
    mat_out{ch} = apply_shifts(obj,shifts,nc_params);
    warning on
end

switch output_format
    case 'tiff'
        begonia.processing.motion_correction.write_tiff(ts,mat_out,output_path);
        ts_out = begonia.scantype.tiff.TSeriesTIFF([output_path,'.tif']);
    case 'h5'
        begonia.processing.motion_correction.write_h5(ts,mat_out,output_path);
        ts_out = begonia.scantype.h5.TSeriesH5([output_path,'.h5']);
    otherwise
        error('Unknown output format.')
end

% Delete the files from NoRMCorre.
for ch = 1:ts.channels
    motcor_filename = sprintf('motion_corrected_ch%d.h5',ch);
    if exist(motcor_filename,'file')
        delete(motcor_filename);
    end
end

% Tag the tseries as stabilized and calculate mean, max and std
% projections. 
ts_out.save_var('stabilized',true);
for ch = 1:ts.channels
    ts_out.get_avg_img(ch);
    ts_out.get_max_img(ch);
    ts_out.get_std_img(ch);
end

end

