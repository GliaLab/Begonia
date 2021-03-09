function tseries_to_tiff(ts,output_path,merged_frames)
if nargin < 3
    merged_frames = 1;
end

assert(mod(merged_frames(1),1) == 0);
assert(merged_frames(1) > 0);

% Assign metadata that is effected by merging frames. 
frames = floor(ts.frame_count / merged_frames);
dt = ts.dt * merged_frames;

% Assemble what will be in the ImageDescription tag, only supplied so
% ImageJ can read it. 
img_description = sprintf('ImageJ=1.53c\n');
img_description = [img_description, sprintf('images=%d\n', frames * ts.channels)];
img_description = [img_description, sprintf('channels=%d\n', ts.channels)];
img_description = [img_description, sprintf('frames=%d\n', frames)];
img_description = [img_description, sprintf('slices=1\n')];
img_description = [img_description, sprintf('hyperstack=true\n')];
img_description = [img_description, sprintf('mode=color\n')];
img_description = [img_description, sprintf('unit=micron\n')];
img_description = [img_description, sprintf('finterval=%g\n',dt)];
img_description = [img_description, sprintf('fps=%g\n',1/dt)];
img_description = [img_description, sprintf('loop=false\n')];

% Assemble the metadata / properties of the TSeries which will be stored in
% the Software tag. 
metadata = struct;
metadata.name = ts.name;
metadata.cycles = ts.cycles;
metadata.channels = ts.channels;
metadata.channel_names = ts.channel_names;
metadata.frame_count = frames;
metadata.img_dim = ts.img_dim;
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

% Assemble necessary data for the TIFF format as well as X and Y
% resolution.
tags.ImageLength = ts.img_dim(1);
tags.ImageWidth = ts.img_dim(2);
tags.Photometric = Tiff.Photometric.MinIsBlack;
tags.Compression = Tiff.Compression.None;
tags.BitsPerSample = 16;
tags.SamplesPerPixel = 1;
tags.SampleFormat = Tiff.SampleFormat.UInt;
tags.RowsPerStrip = ts.img_dim(1);
tags.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
tags.ResolutionUnit = Tiff.ResolutionUnit.None;
if ~isempty(ts.dx)
    tags.XResolution = 1/ts.dx;
end
if ~isempty(ts.dy)
    tags.YResolution = 1/ts.dy;
end

% Write tiff
begonia.path.make_dirs(output_path);
t = Tiff(output_path, 'w8');
for ch = 1:ts.channels
    mat{ch} = ts.get_mat(ch);
end
begonia.logging.backwrite();
for frame = 1:frames
    if frame == frames
        begonia.logging.backwrite(1,'Writing tiff (100%%) > %s',output_path);
    elseif mod(frame,ceil(frames/100)) == 0
        begonia.logging.backwrite(1,'Writing tiff (%d%%) > %s',round(frame/frames*100),output_path);
    end
    
    for ch = 1:ts.channels
        frame_orig = (frame-1)*merged_frames+1;
        t.setTag(tags)
        if frame == 1 && ch == 1
            t.setTag('ImageDescription',img_description);
            t.setTag('Software',metadata);
        end
        t.write(uint16(mean(mat{ch}(:,:,frame_orig:frame_orig + merged_frames - 1),3)));
        t.writeDirectory();
    end
end
t.close()
end

