classdef SingleImage  < handle & begonia.data_management.DataInfo
    %SINGLEIMAGE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Abstract)
        frame_position_um
    end
    
    methods (Abstract)
        mat = get_mat(self,cycle,channel);
    end
end

