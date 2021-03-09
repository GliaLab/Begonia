classdef BackgroundTask
    %BACKGROUNDJOB Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        job_handle
        dloc
        variables
        title
    end
    
    methods
        function obj = BackgroundTask(job_handle, dloc, variables)
            obj.job_handle = job_handle;
            obj.dloc = dloc;
            obj.variables = variables;
            obj.title = 'Untitled job'
        end
    end
end

