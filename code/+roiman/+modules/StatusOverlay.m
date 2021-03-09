classdef StatusOverlay < roiman.ViewModule & handle
    %OVERLAY Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        ax
        
        mode_key
        message_key
        
        % handles:
        rect_handle
        text_handle
    end
    
    methods
        function obj = StatusOverlay(name)
            obj@roiman.ViewModule(name, "status");
            
            obj.mode_key = "mode";
            obj.message_key = "message";
        end

        function on_init(obj, manager, view)
            [~, m_write, m_read] = manager.data.shorts();
            dims = m_read("dimensions");
            
            obj.ax = view.request_ax(dims(1), dims(2), false);
            obj.rect_handle = rectangle(obj.ax, "position", [0 dims(2)-19 dims(1) 20] ...
                , "FaceColor", [0 0 0 .5] ...
                , "LineWidth", 0.5);
            obj.text_handle = text(obj.ax, 10, dims(2)-10, "--", "color", "white", "fontsize", 9);
            
            hold(obj.ax, "on")
        end
        
        function on_enable(obj, manager, view)
            %warning("on_enable :: not implemented for " + obj.name);
        end
        
        function on_update(obj, manager, view)
            [~, m_write, m_read] = manager.data.shorts();
            [~, v_write, v_read] = view.data.shorts();
            
            xl = xlim();
            yl = ylim(); 
            
            % calculate the dimentions un display units:
            dims = m_read("dimensions");
            vp = v_read("viewport", [0 0 dims]);
            
            dunit = m_read("dunit");
            convfunc = m_read("pix_to_dunit");
            
            size_str = join(string(round(arrayfun(convfunc ,[vp(3) vp(4)]))), "x") + dunit;
            
            % create the status string:
            mode_str = m_read(obj.mode_key).name;
            msg_str = m_read(obj.message_key);
            str = join([mode_str, size_str, msg_str], ' | ');
            
            % FIXME: dont hardcode this:
%             obj.rect_handle = rectangle(obj.ax, "position", [0 512-19 512  20] ...
%                 , "FaceColor", [0 0 0 .5] ...
%                 , "LineWidth", 0.5) 
%             
%             % FIXME: remove this hardcoding:
%             text(obj.ax, 10, 502, str, "color", "white", "fontsize", 9);
            obj.text_handle.String = str;
        end
    end
end

