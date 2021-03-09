classdef ZoomData < handle
    properties
        figure
        
        ax_image
        ax_plot
        ax_cross
        ax_overlay
        
        zoomables

        data_dim        % data dimention
        win_dim         % window dimension
        viewport        % part of data displayed
        
        mouse_vp
        mouse_win
    end
end

