classdef MementoAction < handle

    properties
        edit_action
        description
        undo_action
        can_undo
    end
    
    methods
        function obj = MementoAction(edit_action, description, undo_action)
            obj.edit_action = edit_action;
            obj.description = description;
            
            % if we are provided an undo parameter, we can undo the action:
            obj.can_undo = nargin > 2;
            if obj.can_undo
                obj.undo_action = undo_action;
            end
        end
    end
end

