% Input managers deal with inputs in views. There is only one input manager
% active at a time, and it operats on the frontmost view. They capture
% mouse positions and click + keyboard events. E.g. if a user drags the
% mouse when painting rois, they the RoiPaintIM handles capturing the drag
% state, and passes the data along to the roi paint mode object.
classdef (Abstract) ViewInputManager < handle
    
    properties
        name
        mark
    end
    
    methods 
        
        function obj = ViewInputManager(name, mark)
            obj.name = name;
            obj.mark = mark;
        end
        
        % called when a view comes fron
        function attach(obj, manager, view)
            fig = view.figure;
            fig.WindowScrollWheelFcn = @(s, e) obj.on_scrollwheel(manager, view, e);
            fig.WindowButtonDownFcn = @(s, e) obj.on_mousedown(manager, view, e);
            fig.WindowButtonUpFcn = @(s, e) obj.on_mouseup(manager, view, e);
            fig.WindowButtonMotionFcn = @(s, e) obj.handle_mousemove(manager, view, e);
        end
        
        
        % called whent the input manager changes
        function detach(obj, view)
            fig = view.figure();
            fig.WindowScrollWheelFcn = '';
            fig.WindowButtonDownFcn = '';
            fig.WindowButtonUpFcn = '';
            fig.WindowButtonMotionFcn = '';
        end
        
        
        % override to deal with mouse scoll events:
        function on_scrollwheel(obj, manager, view, event)
            warning("on_scrollwheel not iomplemented for input manager: " + obj.name);
            
            dist = event.VerticalScrollCount * event.VerticalScrollAmount;
        end
        
        
        function on_mousedown(obj, manager, view, event)
            warning("on_mousedown not iomplemented for input manager: " + obj.name);
        end
        
        
        function on_mouseup(obj, manager, view, event)
            warning("on_mouseup not iomplemented for input manager: " + obj.name);
        end
        
        function handled = on_mousemove(obj, manager, view, event)
            handled = false;
        end
        
    end
    
    methods(Access=private)
        
        function handle_mousemove(obj, manager, view, event) 
            % first, let the view handle the event, then the input handler:
            view.on_mousemove();
            obj.on_mousemove(manager, view, event);
        end
        
    end
    

end

