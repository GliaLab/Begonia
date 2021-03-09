function make_roa_video(ts,channel,filepath,contrast_factor,frames_per_tick,video_fps)
if nargin < 4
    contrast_factor = 0.98;
end
if nargin < 5
    frames_per_tick = 1;
end
if nargin < 6
    video_fps = 1/ts.dt;
end
roa_param_hidden = ts.load_var('roa_param_hidden',[]);
if isempty(roa_param_hidden)
    return;
end

roa_param_hidden = roa_param_hidden(channel);

if ~roa_param_hidden.roa_enabled
    return;
end

if ~endsWith(filepath,'.mp4')
    filepath = [filepath,'.mp4'];
end
%% Load ROA
% ROA ignore mask.
if ts.has_var('roa_ignore_mask')
    roa_ignore_mask = ts.load_var('roa_ignore_mask');
else
    mat = ts.get_mat(1,1);
    dim = size(mat);
    roa_ignore_mask = false(dim(1:2));
end

% Flips it. Result is true where ROAs are allowed.
roa_ignore_mask = ~roa_ignore_mask;

begonia.logging.log(1,'Loading roa_mask');
roa_mask = ts.load_var("roa_mask_ch"+channel,[]);
roa_mask = roa_mask & roa_ignore_mask;
%%
roa_traces = ts.load_var('roa_traces');

roa_freq = roa_traces.roa_frequency_trace{1};
roa_dens = roa_traces.roa_density_trace{1};
%%
mat = ts.get_mat(channel);

img_mu = ts.load_var("roa_img_mu_ch"+channel);
img_mu = img_mu.^2;
clim = [0,max(img_mu(:))*contrast_factor];

dim = size(mat);
%%
f = figure;
f.Position(3:4) = [1200,850];

ax(1) = begonia.util.subplot_tight(3,4,[1,2,5,6]);
im(1) = imagesc(mat(:,:,1),clim);
colormap(ax(1),begonia.colormaps.turbo);
axis equal

ax(2) = begonia.util.subplot_tight(3,4,[3,4,7,8]);
im(2) = imagesc(mat(:,:,1),clim);
colormap(ax(2),gray);
hold on

red_img = zeros(dim(1),dim(2),3);
red_img(:,:,1) = 1;
im_roa = imshow(red_img);
im_roa.AlphaData = false(dim(1),dim(2));

blue_img = zeros(dim(1),dim(2),3);
blue_img(:,:,3) = 1;
im_ignore = imshow(blue_img);
im_ignore.AlphaData = ~roa_ignore_mask;

axis equal

set(ax,'XTickLabel',[])
set(ax,'YTickLabel',[])
set(ax,'XLim',[0,dim(2)])
set(ax,'YLim',[0,dim(1)])
set(ax,'ActivePositionProperty','position');

ax(3) = begonia.util.subplot_tight(3,4,9:12);
if isempty(ts.dt) || isnan(ts.dt)
    xlabel('Frame')
    t_vec = 1:length(roa_freq);
    dt = 1;
else
    xlabel('Time (s)');
    t_vec = (0:length(roa_freq) - 1) * ts.dt;
    dt = ts.dt;
end

yyaxis left
plot(t_vec,roa_freq);
ylabel('ROA Frequency')

yyaxis right
hold on
plot(t_vec,roa_dens);
ylabel('ROA Density')
red_line = plot([0,0],[0,max(roa_dens(:))],'r');
red_line.LineWidth = 2;

filter_vec = begonia.util.gausswin(roa_param_hidden.roa_xy_smooth);
filter_vec = filter_vec .* filter_vec';
filter_vec = filter_vec / sum(filter_vec(:));

begonia.path.make_dirs(filepath);
if exist(filepath,'file')
    delete(filepath);
end
mov = VideoWriter(filepath,'MPEG-4');
mov.FrameRate = video_fps;
mov.open();

L = floor(roa_param_hidden.roa_t_smooth / 2);
i = L + 1;
frame_end = dim(3) - L;

% frames_per_tick = round(ts_fps / video_fps);
% if frames_per_tick < 1
%     warning('Frame rate of the recording cannot be lower than the frame rate of the video. Using minimum');
%     frames_per_tick = 1;
% end

begonia.logging.backwrite();
begonia.logging.backwrite(1,'0%%/100%%');
while i < frame_end
    begonia.logging.backwrite(1,'%d%%/100%%',round(i/frame_end*100));

    img = mean(mat(:,:,i-L:i+L),3);
    img = convn(img,filter_vec);

    im(1).CData = img;
    im(2).CData = img;

    im_roa.AlphaData = roa_mask(:,:,i);

    red_line.XData = ([i,i] - 1) * dt;

    mov.writeVideo(getframe(f));
    i = i + frames_per_tick;
end
mov.close();
begonia.logging.backwrite(1,'100%%/100%%')

close(f);

end