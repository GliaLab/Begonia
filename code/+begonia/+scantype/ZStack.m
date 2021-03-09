classdef ZStack < handle & begonia.data_management.DataInfo
    %ZSTACK Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        frame_position_um
        dzd
    end
    
    methods (Abstract)
        mat = get_mat(self,cycle,channel);
    end
end

