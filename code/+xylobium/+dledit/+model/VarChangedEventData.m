classdef VarChangedEventData < event.EventData
    
    properties
        data_location
        variable_name
        new_value
    end
    
    methods
        
        function obj = VarChangedEventData(dloc, varname, new_value)
            obj = obj@event.EventData();
            obj.data_location = dloc;
            obj.variable_name = varname;
            obj.new_value = new_value;
        end
    end

end

