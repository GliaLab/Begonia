function make_mp4(red, green, outputfile, merged_frames)
 % red and green are 3D matricies (x,y,t) or 0.
if nargin < 1
    red = 0;
end
if nargin < 2
    green = 0;
end
if nargin < 3
    outputfile = "video";
end
if nargin < 4
    merged_frames = 10;
end

[a,b,c] = fileparts(outputfile);
if c ~= ".mp4"
    outputfile = fullfile(a,b + ".mp4");
end
if exist(outputfile,'file')
    delete(outputfile);
end
begonia.path.make_dirs(outputfile);
v = VideoWriter(outputfile,'MPEG-4');
v.Quality = 100;

open(v);

if ~isequal(red, 0)
    dim = size(red);
else
    dim = size(green);
end

img = zeros(dim(1),dim(2),3);

n = dim(1) * dim(2);

if ~isequal(red, 0)
    red1 = double(red(:,:,1));
    red1 = red1(1:floor(n/merged_frames)*merged_frames);
    red1 = reshape(red1,merged_frames,[]);
    red1 = mean(red1,1);
    red_lim = [min(red1),max(red1)];
end

if ~isequal(green, 0)
    green1 = double(green(:,:,1));
    green1 = green1(1:floor(n/merged_frames)*merged_frames);
    green1 = reshape(green1,merged_frames,[]);
    green1 = mean(green1,1);
    green_lim = [min(green1),max(green1)];
end

tic
for frame = 1:merged_frames:dim(3)-merged_frames
    if toc > 5 || frame == 1
        tic
        begonia.logging.log(1,"Writing frame %d/%d (%.f%%)", frame, dim(3), frame/dim(3) * 100);
    end
    if ~isequal(red, 0)
        red_img = red(:,:,frame:frame + merged_frames - 1);
        red_img = mean(red_img,3);
        red_img = red_img - red_lim(1);
        red_img = red_img ./ red_lim(2);
        red_img(red_img<0) = 0;
        red_img(red_img>1) = 1;
        
        img(:,:,1) = red_img; 
    else
        img(:,:,1) = 0;
    end
    
    if ~isequal(green, 0)
        green_img = green(:,:,frame:frame + merged_frames - 1);
        green_img = mean(green_img,3);
        green_img = green_img - green_lim(1);
        green_img = green_img ./ green_lim(2);
        green_img(green_img<0) = 0;
        green_img(green_img>1) = 1;
        
        img(:,:,2) = green_img;
    else
        img(:,:,2) = 0;
    end
    
    v.writeVideo(img);
end
close(v);
begonia.logging.log(1,"Writing frame %d/%d (100%%)", dim(3), dim(3));

end

