classdef IdleMode < roiman.Mode

    properties
        HELP_MSG = "";
        GUIDE_TEXT = "*IDLE*\n\nScrollwheel to move time.\nCtrl-m : to \nClick rois to select\n";
    end
    
    
    methods
        function obj = IdleMode()
            obj = obj@roiman.Mode("IDLE", "space");
        end

        function on_activate(obj, manager)
            [~, m_write, m_read] = manager.data.shorts();
            m_write("message", obj.HELP_MSG)
            m_write("guide_text", replace(obj.GUIDE_TEXT, "\n", newline))
        end
        
        
        function on_mouse(obj, type, manager, view, event)
            [~, m_write, m_read] = manager.data.shorts();
            
            % in idle mode (default), we scroll by wheel:
            if type == "wheel"
                dist = event.VerticalScrollCount * event.VerticalScrollAmount;
                frame = m_read("current_frame");
                frames = m_read("frames");

                frame = frame - dist;
                if frame <= 0
                    frame = frames(end) + frame;
                    m_write("message", "LOOPED TO END");
                elseif frame > frames(end)
                    frame = frame - frames(end);
                    m_write("message", "LOOPED TO START");
                end

                manager.goto(frame) 
            end
        end
        
    end
end

