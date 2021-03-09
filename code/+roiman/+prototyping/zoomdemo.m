clear

zdata = setup();

function zdata = setup()
    % data and dimentions
    img = rgb2gray(imread("pluto.jpg"));

    data_dim = size(img);       % data dimention
    win_dim = [500 500];        % window dimension
    viewport = [0 0 data_dim];  % area being viewed currently


    %% setup test:
    fig = figure("Position", [0 0 win_dim], "color", "black");
    ax_img = axes(fig, "Position", [0 0 1 1]);
    hold(ax_img, 'on')

    ax_plot = axes(fig, "Position", [0 0 1 1], "color", "none");
    hold(ax_plot, 'on')

    ax_cross = axes(fig, "Position", [0 0 1 1], "color", "none");
    hold(ax_cross, 'on')
    
    ax_overlay = axes(fig, "Position", [0 0 1 1], "color", "none");
    hold(ax_overlay, 'on')
    xlim(ax_overlay, [0 100]); 
    ylim(ax_overlay, [0 100]); 
    
    albedo = 200;
    img_bin = img > albedo;
    imagesc(ax_img, img);
    colormap(ax_img, begonia.colormaps.turbo)
    hold on
    bounds = bwboundaries(img_bin);
    bounds = bounds(cellfun(@length, bounds) > 200);
    for k = 1:length(bounds)
        boundary = bounds{k};
        plot(ax_plot, boundary(:,2), boundary(:,1), 'w', 'LineWidth', 2)
    end

    % create the zdata:
    zdata = roiman.prototyping.ZoomData();
 
    zdata.figure = fig;
    zdata.ax_image = ax_img;
    zdata.ax_plot = ax_plot;
    zdata.ax_cross = ax_cross;
    zdata.ax_overlay = ax_overlay;
    
    zdata.data_dim = data_dim;
    zdata.win_dim = win_dim;
    zdata.viewport = viewport;
    
    zdata.zoomables = [ax_img, ax_plot, ax_cross];
    
    % assign event handlers:
    fig.KeyReleaseFcn = @(~, ev) on_keyup(ev, zdata);
    fig.WindowButtonMotionFcn = @(~, ev) on_mousemove(ev, zdata);
    fig.SizeChangedFcn = @(~, ev) on_resize(ev, zdata);
    
    update(zdata);
end

%% handlers:
function on_keyup(ev, zdata)
    key = lower(ev.Key);
    if key == "x"
        zoom(zdata, 1/2);
    elseif key == "z"
        zoom(zdata, 2);
    elseif key == "c"
        center(zdata);
    elseif key == "v"
        zoom_reset(zdata);
    end
end

function on_resize(ev, zdata) 
    new_pos = zdata.figure.Position;
    zdata.win_dim = [new_pos(3) new_pos(4)];
    update(zdata);
end

function on_mousemove(ev, zdata) 
    vp = zdata.viewport;
    wd = zdata.win_dim;

    % x and y coordinate of the window:
    win_x = zdata.figure.CurrentPoint(1);
    win_y = zdata.figure.CurrentPoint(2);
    
    % convert to viewport coordinate
    x_ratio = vp(3) / wd(1);
    y_ratio = vp(4) / wd(2);
    vp_x = vp(1) + (win_x * x_ratio);
    vp_y = vp(2) + (win_y * y_ratio);
    
    pos_str = "WIN: " + round(win_x) + "," + round(win_y) ...
        + " VIEWPORT: " + round(vp_x) + "," + round(vp_y);
    
    cla(zdata.ax_overlay);
    text(zdata.ax_overlay, 5, 95, pos_str, "color", "white");

    ax = zdata.ax_cross;
    cla(ax);
    scatter(ax, vp_x, vp_y, "r*")
    
    zdata.mouse_vp = [vp_x, vp_y];
    zdata.mouse_win = [win_x, win_y];
end


function zoom(zdata, factor)
    % calculate the new viewport based on the zoom factor:
    w = zdata.viewport(3) * factor;
    h = zdata.viewport(4) * factor;
    offset_x = zdata.mouse_vp(1) - w/2;
    offset_y = zdata.mouse_vp(2) - h/2;
    
    % make the new viewport
    vp = [offset_x, offset_y, w, h];
    zdata.viewport = vp;
    
    update(zdata);
end


function zoom_reset(zdata)
    zdata.viewport = [0 0 zdata.data_dim];
    update(zdata);
end


function center(zdata)
    w = zdata.viewport(3);
    h = zdata.viewport(4);
    offset_x = zdata.mouse_vp(1) - w/2;
    offset_y = zdata.mouse_vp(2) - h/2;
    
    zdata.viewport = [offset_x, offset_y, w, h];
    
    update(zdata);
end


function update(zdata)
    xl = [zdata.viewport(1), zdata.viewport(1) + zdata.viewport(3)];
    yl = [zdata.viewport(2), zdata.viewport(2) + zdata.viewport(4)];
    for ax = zdata.zoomables
        xlim(ax, xl)
        ylim(ax, yl)
    end
end
