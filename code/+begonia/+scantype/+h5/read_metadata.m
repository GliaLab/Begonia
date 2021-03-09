function metadata = read_metadata(path)

assert(isequal(path(end-2:end),'.h5'),'File must end in .h5');

metadata = struct;
metadata.name               = [];
metadata.frame_count        = [];
metadata.slices             = [];
metadata.channel_names      = [];
metadata.channels           = [];
metadata.img_dim            = [];
metadata.dt                 = [];
metadata.dx                 = [];
metadata.dy                 = [];
metadata.cycles             = [];
metadata.zoom               = [];
metadata.start_time         = [];
metadata.duration           = [];
metadata.source             = [];

tmp = jsondecode(h5readatt(path,'/recording','json_metadata'));
% Assign properties from the struct 'tmp' to the metadata struct.
f = fieldnames(tmp);
for i = 1:length(f)
    metadata.(f{i}) = tmp.(f{i});
end

if ~isempty(metadata.start_time)
    metadata.start_time = datetime(metadata.start_time,'InputFormat','uuuu/MM/dd HH:mm:ss');
end
metadata.duration = seconds(metadata.duration);
end

