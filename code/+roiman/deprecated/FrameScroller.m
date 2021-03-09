classdef FrameScroller < roiman.ViewInputManager
    %FRAMESCROLLER Summary of this class goes here
    %   Detailed explanation goes here
    
    methods
    
        
        function obj = FrameScroller()
            obj@roiman.ViewInputManager("Wheel scroller", "scroll frame");
        end
        
        
        function on_scrollwheel(obj, manager, view, event)
            dist = event.VerticalScrollCount * event.VerticalScrollAmount;
            frame = manager.data.read("current_frame");
            frames = manager.data.read("frames");
           
            frame = frame - dist;
            if frame <= 0
                frame = frames(end) + frame;
                manager.data.write("message", "LOOPED TO END");
            elseif frame > frames(end)
                frame = frame - frames(end);
                manager.data.write("message", "LOOPED TO START");
            end
            
            manager.goto(frame)
        end
        
    end
end

