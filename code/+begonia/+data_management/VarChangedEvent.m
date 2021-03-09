classdef VarChangedEvent < event.EventData
    %VARCHANGEDEVENT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        varname
    end
    
    methods
        function obj = VarChangedEvent(varname)
            obj.varname = varname;
        end
    end
end

