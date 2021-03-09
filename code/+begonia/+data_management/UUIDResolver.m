classdef (Abstract) UUIDResolver < handle
    methods (Abstract)
        data = get_data(uuid); 
        info = get_info(uuid); 
    end
end

