function metadata = read_metadata(xml_path)
if ~exist(xml_path, 'file')
    metadata = [];
    return;
end

text = fileread(xml_path);

[~, filename,ext] = fileparts(xml_path);
metadata.xml_file = [filename,ext];

temp = regexp(text,'(?<="framePeriod" value=").*?(?=")','match');
if length(temp) > 1
    metadata.dt = str2double(temp(2:end));
else
    metadata.dt = str2double(temp(1:end));
end

temp = regexp(text,'(?<="linesPerFrame" value=").*?(?=")','match');
metadata.linesPerFrame = temp(2:end);
metadata.linesPerFrame = cellfun(@(x) str2num(x), metadata.linesPerFrame);

temp = regexp(text,'(?<=<PVStateValue key="micronsPerPixel">).*?(?=</PVStateValue>)','match');
temp = regexp(temp,'(?<="XAxis" value=").*?(?=")','match');
metadata.dx = str2double(temp{1});

temp = regexp(text,'(?<=<PVStateValue key="micronsPerPixel">).*?(?=</PVStateValue>)','match');
temp = regexp(temp,'(?<="YAxis" value=").*?(?=")','match');
metadata.dy = str2double(temp{1});

temp = regexp(text,'(?<=type=").*?(?=")','match');
metadata.type = temp{1};

temp = regexp(text,'(?<="opticalZoom" value=").*?(?=")','match');
metadata.optical_zoom = str2double(temp{1});

temp = regexp(text,'(?<="pixelsPerLine" value=").*?(?=")','match');
metadata.img_dim = [str2num(temp{1}) str2num(temp{1})];

temp = regexp(text,'(?<=Freehand x=").*?(?=")','match');

metadata.line_x = cellfun(@(x) str2double(x), temp);

temp = regexp(text,'(?<= y=").*?(?=")','match');
metadata.line_y = cellfun(@(x) str2double(x), temp);

temp = regexp(text,'(?<=key="scanLinePeriod" value=").*?(?=")','match');
metadata.line_period = cellfun(@(x) str2double(x), temp(2:end));

temp = regexp(text,'(?<=relativeTime=").*?(?=")','match');
metadata.relative_times = cellfun(@(x) str2double(x), temp);

temp = regexp(text,'(?<=absoluteTime=").*?(?=")','match');
metadata.absolute_times = cellfun(@(x) str2double(x), temp);

% number of frames averaged for each frame:
temp = regexp(text,'(?<="rastersPerFrame" value=").*?(?=")','match');
metadata.rasters_pr_frame = cellfun(@(x) str2double(x), temp);

temp = regexp(text,'(?<=date=").*?(?=")','match');
metadata.start_time = datetime(temp,'InputFormat','MM/dd/uuuu hh:mm:ss aa');
if ~isempty(metadata.absolute_times)
    metadata.start_time = metadata.start_time + seconds(metadata.absolute_times(1));
end
metadata.start_time.Format = 'uuuu/MM/dd HH:mm:ss';

% Matches any characters that are not whitespace (\S) which is
% also between 'filename="' and '"' .
temp = regexp(text,'(?<=filename=")\S*?\.ome\.tif(?=")','match');
metadata.files = temp;

tmp_cy = cell(length(temp),1);
tmp_ch = cell(length(temp),1);
for i = 1:length(temp)
    tmp_cy{i} = temp{i}(end-23:end-19);
    tmp_ch{i} = temp{i}(end-17:end-15);
end
metadata.cycles = length(unique(tmp_cy));
tmp_ch = unique(tmp_ch);
metadata.channels = length(tmp_ch);
metadata.channel_names = tmp_ch;
metadata.files = reshape(metadata.files,metadata.cycles,metadata.channels,[]);
% The previous code of sorting the files brakes if the cycles
% dont have equally many frames, so we juse use that data to
% create frames_in_cycle.
metadata.frames_in_cycle = repmat(size(metadata.files,3),1,metadata.cycles);

% Try to read the position of the frames.
try 
    temp = regexp(text,'(?<=<PVStateValue key="positionCurrent">).*?(?=</PVStateValue>)','match');

    x_temp = regexp(temp,'(?<=<SubindexedValues index="XAxis">).*?(?=</SubindexedValues>)','match');
    x = regexp(x_temp{:},'(?<=subindex="0" value=").*?(?=")','match');
    x = str2double(x{:});

    y_temp = regexp(temp,'(?<=<SubindexedValues index="YAxis">).*?(?=</SubindexedValues>)','match');
    y = regexp(y_temp{:},'(?<=subindex="0" value=").*?(?=")','match');
    y = str2double(y{:});

    z_temp = regexp(temp,'(?<=<SubindexedValues index="ZAxis">).*?(?=</SubindexedValues>)','match');
    z = regexp(z_temp{:},'(?<=subindex="0" value=").*?(?=")','match');
    z = str2double(z{:});
    metadata.frame_position_um = [x,y,z];
catch 
    metadata.frame_position_um = [];
end

end