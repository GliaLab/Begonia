classdef QueueExecutionError < handle
    %QUEUEEXECUTIONERROR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        action
        error
        time
    end
    
    methods
        function obj = QueueExecutionError(action,err)
            obj.action = action;
            obj.error = err;
            obj.time = datetime();
        end
    end
end

