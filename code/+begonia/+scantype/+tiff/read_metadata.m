function metadata = read_metadata(path)
% Load metadata from the tif file and return a struct. 

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
metadata.tiff_source        = [];
metadata.frame_position_um  = [];

warning off
tif = Tiff(path);
warning on

[~,filename,ext] = fileparts(path);
metadata.name = [filename,ext];

% Try to guess the format based on some hints in the metadata.
format = '';
try
    str = tif.getTag('Software');
    if strcmp(str(1:2),'SI')
        % Scan image starts its metdata with SI.
        format = 'ScanImage';
    elseif strcmp(str(1),'{')
        % In begonia's format the metadata is encoded with json that starts
        % with a squiggly bracket. 
        format = 'Begonia';
    end
end
if isempty(format)
    try
        str = tif.getTag('ImageDescription');
        if strcmp(str(1:7),'ImageJ=')
            format = 'ImageJ';
        elseif strcmp(str(1:8),'Creator:')
            format = 'Sutter';
        end
    end
end

metadata.tiff_source = format;

switch format
    case 'ScanImage'
        evalc(tif.getTag('ImageDescription'));
        evalc(tif.getTag('Software'));

        metadata.channel_names = ...
            SI.hChannels.channelName(SI.hChannels.channelSave);
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
        
        % The number of frames is included in the metadata from scanimage,
        % but if the recording was interrupted early the number of frames
        % is not correct. Here the real number of frames is found by
        % searching for the last frame that can be read using the interval
        % halving method. 
        total_dirs = metadata.frame_count * metadata.channels;
        warning off
        % Load the tiffstack using the modified TIFFStack library. This
        % allows to load the tiff without reading all the header
        % information and speeds up loading. 
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
        % In the "Begonia" format all the metadata is written to the
        % Software tag with json encoding. 
        tmp = jsondecode(tif.getTag('Software'));
        % Assign properties from the struct 'tmp' to the metadata struct.
        f = fieldnames(tmp);
        for i = 1:length(f)
            metadata.(f{i}) = tmp.(f{i});
        end
        % Change the format of the start time. 
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
        if isempty(channels)
            metadata.channels = 1;
            metadata.channel_names = {'Channel 1'};
        else
            metadata.channels = str2double(channels{1});
            channel_names = {};
            for ch = 1:metadata.channels
                channel_names{ch} = sprintf('Channel %d',ch);
            end
            metadata.channel_names = channel_names;
        end
        
        % Find dt
        dt = regexp(str,'(?<=finterval=).*?(?=\n)','match');
        fps = regexp(str,'(?<=fps=).*?(?=\n)','match');
        if ~isempty(dt)
            metadata.dt = str2double(dt{1});
        elseif ~isempty(fps)
            metadata.dt = 1/str2double(fps{1});
        end
        
        try
            metadata.dx = 1/tif.getTag('XResolution');
            metadata.dy = 1/tif.getTag('YResolution');
        end
        
        if ~isempty(metadata.dt)
            metadata.duration = seconds(metadata.dt * metadata.frame_count);
        end
        
        metadata.img_dim = size(tif.read());
        
        metadata.cycles = 1;
        metadata.source = 'Unknown';
        
    case 'Sutter'
        str = tif.getTag('ImageDescription');
        
        % Find the number of channels. 
        metadata.channels = length(strfind(str,': Saved'));      
        metadata.channel_names = {};
        for i = 1:metadata.channels
            expression = sprintf('(?<=Channel %d Name: ).*?(?=\n)',i);
            channel_name = regexp(str,expression,'match');
            channel_name = channel_name{1};
            channel_name = channel_name(1:end-1);
            metadata.channel_names{i} = channel_name;
        end
        
        
        dt = regexp(str,'(?<=Frame Duration: ).*?(?= s)','match');
        dt = dt{1};
        metadata.dt = str2double(dt);
        
        % Find the number between "Microns per pixel: " and "m". The greek
        % mu symbol for micrometer is included in the string and is removed
        % before converting the string to a double. 
        dx = regexp(str,'(?<=Microns per pixel: ).*?(?=m)','match');
        dx = dx{1};
        % Remove the greek symbol, mu, from the end of the string. 
        dx = dx(1:end-1);
        metadata.dx = str2double(dx);
        metadata.dy = metadata.dx;
        
        % Find the microscope position.
        tmp = regexp(str,'(?<=X Stage position: ).*?(?=m)','match');
        tmp = tmp{1};
        % Remove the greek symbol, mu, from the end of the string. 
        tmp = tmp(1:end-1);
        xpos = str2double(tmp);
        
        tmp = regexp(str,'(?<=Y Stage position: ).*?(?=m)','match');
        tmp = tmp{1};
        % Remove the greek symbol, mu, from the end of the string. 
        tmp = tmp(1:end-1);
        ypos = str2double(tmp);
        
        tmp = regexp(str,'(?<=Z Stage position: ).*?(?=m)','match');
        tmp = tmp{1};
        % Remove the greek symbol, mu, from the end of the string. 
        tmp = tmp(1:end-1);
        zpos = str2double(tmp);
        
        metadata.frame_position_um = [xpos,ypos,zpos];
        
        tmp = regexp(str,'(?<=Magnification: ).*?(?=x)','match');
        tmp = tmp{1};
        tmp = tmp(1:end-1);
        metadata.zoom = str2double(tmp);
        
        metadata.cycles = 1;
        metadata.source = 'Sutter';
        
        info = imfinfo(path);
        metadata.frame_count = length(info) / metadata.channels;
        metadata.img_dim = size(tif.read());
        
        metadata.duration = seconds(metadata.dt * metadata.frame_count);
        
    otherwise
        % Use TIFFStack to check all dimensions. 
        mat = TIFFStack(path);
        dim = size(mat);
        metadata.img_dim = dim(1:2);
        metadata.frame_count = dim(3);
        
        try
            metadata.dx = 1/tif.getTag('XResolution');
            metadata.dy = 1/tif.getTag('YResolution');
        end
        
        metadata.cycles = 1;
        metadata.channels = 1;
        metadata.channel_names = {'Channel 1'};
        metadata.source = 'Unknown';
end

metadata.img_dim = reshape(metadata.img_dim,1,[]);
end

