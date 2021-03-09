function metadata = read_metadata(path)
% Load a certain data from the metadata from the tif file and
% returns a struct of that data. 

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

warning off
tif = Tiff(path);
warning on

[~,filename,ext] = fileparts(path);
metadata.name = [filename,ext];

% Try to read metadata from known formats.
format = '';
try
    str = tif.getTag('Software');
    if isequal(str(1:2),'SI')
        format = 'ScanImage';
    elseif isequal(str(1),'{')
        format = 'Begonia';
    end
end

if isempty(format)
    try
        str = tif.getTag('ImageDescription');
        if isequal(str(1:7),'ImageJ=')
            format = 'ImageJ';
        end
    end
end

switch format
    case 'ScanImage'
        
        evalc(tif.getTag('ImageDescription'));
        evalc(tif.getTag('Software'));

        metadata.channel_names = SI.hChannels.channelName;
        metadata.channels = length(metadata.channel_names);
        metadata.img_dim(1) = SI.hRoiManager.linesPerFrame;
        metadata.img_dim(2) = SI.hRoiManager.pixelsPerLine;
        metadata.dt = SI.hRoiManager.scanFramePeriod;
        metadata.zoom = SI.hRoiManager.scanZoomFactor;
        metadata.cycles = SI.hCycleManager.totalCycles;
        metadata.frame_count = SI.hStackManager.framesPerSlice;
        metadata.start_time = datetime(epoch);
        metadata.start_time.Format = 'uuuu/MM/dd HH:mm:ss';
        metadata.duration = seconds(metadata.frame_count * metadata.dt);
        metadata.source = 'ScanImage';
        
        width_um = SI.hRoiManager.imagingFovUm(3,1) - SI.hRoiManager.imagingFovUm(1,1);
        height_um = SI.hRoiManager.imagingFovUm(3,2) - SI.hRoiManager.imagingFovUm(1,2);
        
        metadata.dx = width_um / metadata.img_dim(2);
        metadata.dy = height_um / metadata.img_dim(1);
        
        % Find the last frame by searching for the last frame that can be
        % read.
        total_dirs = metadata.frame_count * metadata.channels;
        
        warning off
        mat = TIFFStack(path,[],metadata.channels,true,total_dirs);
        warning on
        
        frame_low = 1;
        frame_high = metadata.frame_count;
        frame_current = frame_high;
        
        while frame_high - frame_low > 1
            try
                img = mat(:,:,metadata.channels,frame_current);
                frame_low = frame_current;
            catch e
                frame_high = frame_current;
            end
            
            frame_current = frame_low + floor((frame_high - frame_low)/2);
        end
        
        metadata.frame_count = frame_current;
    case 'Begonia'
        tmp = jsondecode(tif.getTag('Software'));
        % Assign properties from the struct 'tmp' to the metadata struct.
        f = fieldnames(tmp);
        for i = 1:length(f)
            metadata.(f{i}) = tmp.(f{i});
        end
        
        if ~isempty(metadata.start_time)
            metadata.start_time = datetime(metadata.start_time,'InputFormat','uuuu/MM/dd HH:mm:ss');
        end
        metadata.duration = seconds(metadata.duration);
    case 'ImageJ'
        str = tif.getTag('ImageDescription');
        
        % Find the number of frames and slices. If the number of frames are missing,
        % but slices is given then use the number of slices as instead. 
        images = regexp(str,'(?<=images=).*?(?=\n)','match');
        frames = regexp(str,'(?<=frames=).*?(?=\n)','match');
        slices = regexp(str,'(?<=slices=).*?(?=\n)','match');
        if ~isempty(frames)
            metadata.frame_count = str2double(frames{1});
            if ~isempty(slices)
                metadata.slices = str2double(slices{1});
            end
        elseif ~isempty(slices)
            metadata.frame_count = str2double(slices{1});
        elseif ~isempty(images)
            metadata.frame_count = str2double(images{1});
        end
        
        % Find channels. 
        channels = regexp(str,'(?<=channels=).*?(?=\n)','match');
        if ~isempty(channels)
            metadata.channels = str2double(channels{1});
            channel_names = {};
            for ch = 1:metadata.channels
                channel_names{ch} = sprintf('Channel %d',ch);
            end
            metadata.channel_names = channel_names;
        end
        
        % Find dt
        finterval = regexp(str,'(?<=finterval=).*?(?=\n)','match');
        fps = regexp(str,'(?<=fps=).*?(?=\n)','match');
        if ~isempty(finterval)
            metadata.dt = str2double(finterval{1});
        elseif ~isempty(fps)
            metadata.dt = 1/str2double(fps{1});
        end
end

% Check x and y resolution if missing. 
if isempty(metadata.dx) || isempty(metadata.dy)
    try
        metadata.dx = 1/tif.getTag('XResolution');
        metadata.dy = 1/tif.getTag('YResolution');
    end
end

% Check the dimensions by opening the file. 
if isempty(metadata.frame_count)
    % Use TIFFStack to check all dimensions. 
    mat = TIFFStack(path);
    dim = size(mat);
    metadata.img_dim = dim(1:2);
    metadata.frame_count = dim(3);
elseif isempty(metadata.img_dim)
    metadata.img_dim = size(tif.read());
end

if ~isempty(metadata.dt)
    metadata.duration = seconds(metadata.dt * metadata.frame_count);
end

if isempty(metadata.cycles)
    metadata.cycles = 1;
end

if isempty(metadata.channels)
    metadata.channels = 1;
    metadata.channel_names = {'Channel 1'};
end

if isempty(metadata.source)
    metadata.source = 'Unknown';
end

metadata.img_dim = reshape(metadata.img_dim,1,[]);
end

