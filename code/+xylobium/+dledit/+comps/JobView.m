classdef JobView < handle
    %JOBVIEW Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        figure
        model
        position
        table
    end
    
    properties(Access = private)
        job_done_listener;
        job_added_listener;
    end
    
    methods
        function obj = JobView(model, fig, pos)

            if nargin < 2
                fig = figure('Position', [100,100, 250, 500]);
                fig.CloseRequestFcn = @obj.handleClose;
                
                fig.ToolBar = 'none';
                fig.MenuBar = 'none';
                fig.Name = 'Jobs list';
                fig.NumberTitle = 'off';
                pos = [0, 0, 1, 1];
            end
            
            obj.model = model;
            obj.figure = fig;
            obj.position = pos;
            
            obj.table = uitable(fig, 'units', 'normalized');
            obj.table.Position = pos;
            obj.table.ColumnName = {'S', 'Name', 'Status'};
            obj.table.ColumnWidth = {20, 150, 80};
            obj.table.RowName = {};
            
            % initially load all data:
            obj.handleJobsChanged();
            
            % set up event handlers:
            obj.job_done_listener = addlistener(model, 'on_job_done', @obj.handleJobsChanged);
            obj.job_added_listener = addlistener(model, 'on_job_added', @obj.handleJobsChanged);
        end
        
        
        function handleClose(obj, ~, ~)
           delete(obj.job_done_listener);
           delete(obj.job_added_listener);
           delete(obj.figure)
        end
        
        
        function handleJobsChanged(obj, ~, ~)
            jobs = {};

            % completed jobs:
            for i = 1:length(obj.model.jobs_completed)
                title = obj.model.jobs_completed(i).title;
                status = obj.model.jobs_completed(i).job_handle.State;
                jobs = vertcat({'-', title, status}, jobs);
            end
            
            % active jobs:
            for i = 1:length(obj.model.jobs)
                title = obj.model.jobs(i).title;
                status = obj.model.jobs(i).job_handle.State;
                jobs = vertcat({'>>', title, status}, jobs);
            end
            

            obj.table.Data = jobs;
        end
       
    end
end

