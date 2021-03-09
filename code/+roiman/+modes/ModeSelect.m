classdef ModeSelect < roiman.Mode

    properties
        buffer
    end
    
    methods
        function obj = ModeSelect()
            obj = obj@roiman.Mode("MODE-SELECT", "");
        end

        
        function on_activate(obj, ~)
            obj.buffer = '';
        end
        
        
        function on_keyboard(obj, type, manager, combo, event)
            [~, m_write] = manager.data.shorts();
            
            key = event.Key;
            if key == "return"
                mode = obj.find_mode(manager, string(obj.buffer));
                if ~isempty(mode)
                    manager.set_mode(mode.name);
                else
                    m_write("message", "# Unknown mnemonic: + " + string(obj.buffer) + " - try again, escape to cancel");
                    obj.buffer = [];
                end
            end
            
            if type == "up" && isempty(event.Modifier) && key ~= "control" && key ~= "return" && key ~= "period"
                obj.buffer = [obj.buffer key];
                if ~isempty(strtrim(obj.buffer))
                    m_write("message", "# " + string(obj.buffer));
                end
            end
        end
        
        
        function mode = find_mode(~, manager, mnemonic)
            keys = string(manager.modes.keys);
            for key = keys
                mode = manager.modes(key);
                if mode.mnemonic == mnemonic; return; end
            end
            
            mode = []; % not found
        end
    end
end

