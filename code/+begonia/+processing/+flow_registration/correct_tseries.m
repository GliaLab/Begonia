function ts_out = correct_tseries(ts,output_file,options)

[a,b] = fileparts(output_file);
output_file = fullfile(a,b) + ".h5";

%%
if nargin < 3
    options = OF_options(...
        'input_file', begonia.processing.flow_registration.begonia_file_reader(ts), ... % input path
        'output_path', "optical_flow_tmp/", ... % results folder
        'output_format', 'HDF5', ... % output file format: HDF5, MAT or TIFF
        'alpha', 1.5, ... % smoothness parameter
        'sigma', [2, 2, 0.1; ...  % gauss kernel size channel 1
                  2, 2, 0.1], ... % gauss kernel size channel 2
        'quality_setting', 'balanced', ... % set the quality out of 'fast', 'medium' or 'quality'
        'bin_size', 1, ... % binning over 5 frames from the 30 hz data
        'buffer_size', 500, ... % size of blocks for the parallel evaluation (larger takes more memory)
        'reference_frames', 100:200 ...
        );
end

compensate_recording(options);

%%
if exist(output_file,'file')
    delete(output_file);
end

dim = [ts.img_dim,ts.channels,ts.frame_count];
begonia.path.make_dirs(output_file);
mat_out = begonia.util.H5Array(output_file,dim,'int16', ...
    'dataset_name','/recording');

begonia.logging.backwrite();
cnt = 0;
for ch = 1:ts.channels
    mat = begonia.util.H5Array('optical_flow_tmp/compensated.HDF5', 'dataset_name', sprintf('/ch%d',ch));
    
    c = begonia.util.Chunker(mat,'data_type',class(mat(1,1,1)));
    
    for i = 1:c.chunks
        begonia.logging.backwrite(1,'Writing H5 (%d%%) > %s',round(cnt/c.chunks/ts.channels*100),output_file);
        I = c.chunk_indices(i);
        I2 = {I{1},I{2},ch,I{3}};
        % Permute to apply transpose/flip x and y dimension to make the
        % motion corrected recording the same as the orignal recording.
        mat_out(I2{:}) = permute(mat(I{:}),[2,1,3]);
        cnt = cnt + 1;
    end
end
begonia.logging.backwrite(1,'Writing H5 (100%%) > %s',output_file);

% Assemble the metadata / properties of the TSeries which will be stored in
% as a json string inside an attribute. 
metadata = struct;
metadata.source = ts.source;
metadata.name = ts.name;
metadata.cycles = ts.cycles;
metadata.channels = ts.channels;
metadata.channel_names = ts.channel_names;
metadata.frame_count = ts.frame_count;
metadata.img_dim = reshape(ts.img_dim,1,[]);
metadata.dx = ts.dx;
metadata.dy = ts.dy;
metadata.dt = ts.dt;
metadata.zoom = ts.zoom;
metadata.frame_position_um = ts.frame_position_um;
metadata.start_time = ts.start_time_abs;
if isdatetime(metadata.start_time)
    metadata.start_time.Format = 'uuuu/MM/dd HH:mm:ss';
end
metadata.duration = seconds(ts.duration);
metadata = jsonencode(metadata);

h5writeatt(output_file,'/recording','name',ts.name);
h5writeatt(output_file,'/recording','dx',ts.dx);
h5writeatt(output_file,'/recording','dy',ts.dy);
h5writeatt(output_file,'/recording','dt',ts.dt);
h5writeatt(output_file,'/recording','json_metadata',metadata);

%%
ts_out = begonia.scantype.h5.TSeriesH5(output_file);
%%
delete("optical_flow_tmp/*")
rmdir("optical_flow_tmp")

end

