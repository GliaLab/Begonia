function save_frames_as_h5(ts,output_path,frame_array)
narginchk(3,3);

[a,b] = fileparts(output_path);
output_path = fullfile(a,b) + ".h5";

%% Write data
if exist(output_path,'file')
    delete(output_path);
end

dim = [ts.img_dim(:)',ts.channels,length(frame_array)];
begonia.path.make_dirs(output_path);

mat = ts.get_mat(1);
data_class = class(mat(1,1,1));

mat_out = begonia.util.H5Array(output_path,dim,data_class, ...
    'dataset_name','/recording');

tic
for ch = 1:ts.channels
    mat = ts.get_mat(ch);
    
    for i = 1:length(frame_array)
        if i == 1 || i == length(frame_array) || toc > 5
            tic
            begonia.logging.log(1,'Writing ch %d (%.f%%)',ch,i/length(frame_array)*100);
        end
        
        mat_out(:,:,ch,i) = mat(:,:,frame_array(i));
    end
end

%% Write metadata

% Assemble the metadata / properties of the TSeries which will be stored in
% as a json string inside an attribute. 
metadata = struct;
metadata.source = ts.source;
metadata.name = ts.name;
metadata.cycles = ts.cycles;
metadata.channels = ts.channels;
metadata.channel_names = ts.channel_names;
metadata.frame_count = length(frame_array);
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
metadata.duration = ts.dt * ts.frame_count;
metadata = jsonencode(metadata);

h5writeatt(output_path,'/recording','name',ts.name);
h5writeatt(output_path,'/recording','dx',ts.dx);
h5writeatt(output_path,'/recording','dy',ts.dy);
h5writeatt(output_path,'/recording','dt',ts.dt);
h5writeatt(output_path,'/recording','json_metadata',metadata);
end

