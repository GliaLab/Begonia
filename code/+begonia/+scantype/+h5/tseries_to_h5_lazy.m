function tseries_to_h5_lazy(ts,output_path,merged_frames)
if nargin < 3
    merged_frames = 1;
end

assert(mod(merged_frames(1),1) == 0);
assert(merged_frames(1) > 0);

% Assign metadata that is effected by merging frames. 
frames = floor(ts.frame_count / merged_frames);
dt = ts.dt * merged_frames;

if ~endsWith(output_path,".h5")
    output_path = output_path + ".h5";
end

%% Write data
if exist(output_path,'file')
    delete(output_path);
end
dim = [ts.img_dim(:)',ts.channels,frames];
begonia.path.make_dirs(output_path);

mat = ts.get_mat(1);
data_class = class(mat(1,1,1));

mat_out = begonia.util.H5Array(output_path,dim,data_class, ...
    'dataset_name','/recording');

begonia.logging.log(1,'Writing %s',output_path);
tic
for ch = 1:ts.channels
    begonia.logging.log(1,'Writing ch %d (%d frames)', ch, merged_frames * frames);
    mat = ts.get_mat(ch);
    
    mat = begonia.util.stepping_window(mat,merged_frames);

    mat_out(:,:,ch,:) = mat;
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
metadata.frame_count = frames;
metadata.img_dim = reshape(ts.img_dim,1,[]);
metadata.dx = ts.dx;
metadata.dy = ts.dy;
metadata.dt = dt;
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
h5writeatt(output_path,'/recording','dt',dt);
h5writeatt(output_path,'/recording','json_metadata',metadata);
end

