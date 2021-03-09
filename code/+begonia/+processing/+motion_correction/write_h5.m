function write_h5(ts,mat_cell,output_path)

output_path = [output_path,'.h5'];

%% Write data
if exist(output_path,'file')
    delete(output_path);
end
dim = [ts.img_dim,ts.channels,ts.frame_count];
begonia.path.make_dirs(output_path);
mat_out = begonia.util.H5Array(output_path,dim,'uint16', ...
    'dataset_name','/recording');

begonia.logging.backwrite();
cnt = 0;
for ch = 1:ts.channels
    mat = begonia.util.H5Array(mat_cell{ch},'dataset_name','/mov');
    
    c = begonia.util.Chunker(mat,'data_type',class(mat(1,1,1)));
    
    for i = 1:c.chunks
        begonia.logging.backwrite(1,'Writing H5 (%d%%) > %s',round(cnt/c.chunks/ts.channels*100),output_path);
        I = c.chunk_indices(i);
        I2 = {I{1},I{2},ch,I{3}};
        mat_out(I2{:}) = mat(I{:});
        cnt = cnt + 1;
    end
end
begonia.logging.backwrite(1,'Writing H5 (100%%) > %s',output_path);

%% Write metadata

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

h5writeatt(output_path,'/recording','name',ts.name);
h5writeatt(output_path,'/recording','dx',ts.dx);
h5writeatt(output_path,'/recording','dy',ts.dy);
h5writeatt(output_path,'/recording','dt',ts.dt);
h5writeatt(output_path,'/recording','json_metadata',metadata);

end

