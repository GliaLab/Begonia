classdef Linescan < handle & begonia.data_management.DataInfo
    %LINESCAN Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Abstract)
        first_point
        last_point
        line
    end
    
    methods (Abstract)
        mat = get_mat(self,cycle,channel);
    end
end

