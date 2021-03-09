function write_tiff(ts,mat_out,output_path)

% Assemble what will be in the ImageDescription tag, only supplied so
% ImageJ can read it. 
img_description = sprintf('ImageJ=1.53c\n');
img_description = [img_description, sprintf('images=%d\n', ts.frame_count * ts.channels)];
img_description = [img_description, sprintf('channels=%d\n', ts.channels)];
img_description = [img_description, sprintf('frames=%d\n', ts.frame_count)];
img_description = [img_description, sprintf('slices=1\n')];
img_description = [img_description, sprintf('hyperstack=true\n')];
img_description = [img_description, sprintf('mode=color\n')];
img_description = [img_description, sprintf('unit=micron\n')];
img_description = [img_description, sprintf('finterval=%g\n',ts.dt)];
img_description = [img_description, sprintf('fps=%g\n',1/ts.dt)];
img_description = [img_description, sprintf('loop=false\n')];

% Assemble the metadata / properties of the TSeries which will be stored in
% the Software tag. 
metadata = struct;
metadata.name = ts.name;
metadata.source = ts.source;
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
output_path = [output_path,'.tif'];
begonia.path.make_dirs(output_path);
t = Tiff(output_path, 'w8');
for ch = 1:ts.channels
    mat_out{ch} = begonia.processing.motion_correction.h5arr(mat_out{ch});
end
begonia.logging.backwrite();
for frame = 1:ts.frame_count
    if frame == ts.frame_count
        begonia.logging.backwrite(1,'Writing tiff (100%%) > %s',output_path);
    elseif mod(frame,ceil(ts.frame_count/100)) == 0
        begonia.logging.backwrite(1,'Writing tiff (%d%%) > %s',round(frame/ts.frame_count*100),output_path);
    end
    
    for ch = 1:ts.channels
        t.setTag(tags)
        if frame == 1 && ch == 1
            t.setTag('ImageDescription',img_description);
            t.setTag('Software',metadata);
        end
        t.write(uint16(mat_out{ch}(:,:,frame)));
        t.writeDirectory();
    end
end
t.close()

end

