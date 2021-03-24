%{
Overlay to hold the roi polygon paint tool's controls.
%}
classdef RoIPolygonOverlay < roiman.ViewModule

    properties
        ax
    end
    
    methods
        function obj = RoIPolygonOverlay(name)
            obj@roiman.ViewModule(name, "roipolygonoverlay");
        end

        
        function on_init(obj, manager, view)
            [~, v_write, ~] = view.data.shorts();

            % get ax for this view, keep it for updates:
            dims = manager.data.read('dimensions');
            w = dims(1); 
            h = dims(2);
            obj.ax = view.request_ax(w, h, true);
        end
        
        
        function on_enable(obj, manager, view)
            
        end
        
        
        function on_disable(obj, manager, view)
            
        end
        
        
        function on_update(obj, manager, view)
            
        end
        

    end
end

