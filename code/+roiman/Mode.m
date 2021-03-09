% modes install input managers and deals with events while they are active,
% and edits data based on the user's actions. They can contain static
% methods that alter data. E.g. if an action in the input manager causes a
% roid to be split into to, the mode should have a static function for this
% operation. See the ModeSelect and RoIPaint modes for examples.
classdef (Abstract) Mode < handle

    properties
        name
        mnemonic
    end
    
    methods
        function obj = Mode(name, mnemonic)
            obj.name = name;
            obj.mnemonic = mnemonic;
        end
        
        % called when the mode is first loaded
        function on_init(obj, manager)
            
        end
        
        % called when the user activates the mode
        function on_activate(obj, manager)
            
        end
        

        function on_deactivate(obj, manager)
            
        end
        
        
        function on_keyboard(obj, type, manager, view, event)
            
        end
        
        
        function on_mouse(obj, type, manager, view, event)
            
        end
    end
end

