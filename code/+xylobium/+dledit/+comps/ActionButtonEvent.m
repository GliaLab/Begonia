classdef ActionButtonEvent < event.EventData
    %ACTIONPANELBUTTONEVENT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        action
    end
    
    methods
        function obj = ActionButtonEvent(action)
            obj.action = action;
        end
    end
    
end

