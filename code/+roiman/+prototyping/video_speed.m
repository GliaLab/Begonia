clearvars -except dcat asdata
fig = figure();

a = imread("C:\Users\knuta\Desktop\B.jpg");
b = rot90(rot90(a));
imgs = [{a},{b}];

a_gs = rgb2gray(imread("C:\Users\knuta\Desktop\B.jpg"));
b_gs = rot90(rot90(a_gs));
imgs_gs = [{a_gs},{b_gs}];

pause(1);
disp("Starting speed test");

r = 1;

%% test imshow speeds
for j = 1:50
    tic;
    imgs = circshift(imgs, 1);
    h = imshow(imgs{1});

    t_sec(r,:) = toc;
    test(r,:) = "imshow";
    r = r + 1;
end


%% test direct cdata change
imgs = [{a},{b}];
for j = 1:100
    tic;
    imgs = circshift(imgs, 1);
    h.CData = imgs{1};
    
    t_sec(r,:) = toc;
    test(r,:) = "setting cdata";
    r = r + 1;
end


%% test direct cdata change
imgs = [{a},{b}];
for j = 1:100
    tic;
    imgs = circshift(imgs, 1);
    h.CData = imgs{1};
    drawnow();
    
    t_sec(r,:) = toc;
    test(r,:) = "setting cdata + drawnow";
    r = r + 1;
end


%% test drawnow + pause
for j = 1:100
    tic;
    imgs = circshift(imgs, 1);
    h.CData = imgs{1};
    drawnow(); pause(1/60);
    
    t_sec(r,:) = toc;
    test(r,:) = "setting cdata + drawnow + pause(1/60)";
    r = r + 1;
end


%% test imagesc
for j = 1:100
    tic;
    imgs = circshift(imgs, 1);
    imagesc(imgs{1});
    
    t_sec(r,:) = toc;
    test(r,:) = "imagesc (color)";
    r = r + 1;
end


%% test imagesc
colormap(begonia.colormaps.turbo);
for j = 1:100
    tic;
    imgs_gs = circshift(imgs_gs, 1);
    imagesc(imgs_gs{1});
    
    t_sec(r,:) = toc;
    test(r,:) = "imagesc (grayscale)";
    r = r + 1;
end


%% test imagesc
colormap(begonia.colormaps.turbo);
for j = 1:100
    tic;
    imgs_gs = circshift(imgs_gs, 1);
    imagesc(imgs_gs{1});
    drawnow(); pause(1/60);
    
    t_sec(r,:) = toc;
    test(r,:) = "imagesc (grayscale) + drawnow + pause(1/60)";
    r = r + 1;
end

%% test axis composition
fig = figure();
hold on;
ax_back = axes(fig);
ax_over = axes(fig);
for j = 1:100
    tic;
    imgs_gs = circshift(imgs_gs, 1);
    h1 = imagesc(ax_back, imgs_gs{1});
    h2 = imagesc(ax_over, imgs_gs{2});
    h1.Parent.Position = [rand() rand() rand() rand()];
    h2.Parent.Position = [rand() rand() rand() rand()];
    
    drawnow(); pause(1/60);
    
    t_sec(r,:) = toc;
    test(r,:) = "2x axis + imagesc (grayscale) + drawnow + pause(1/60)";
    r = r + 1;
end

figure();
tab = table(test, t_sec);
boxplot(tab.t_sec, tab.test);
ax = gca();
ax.XTickLabelRotation = 90;



