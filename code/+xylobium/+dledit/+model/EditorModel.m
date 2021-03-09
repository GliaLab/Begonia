%{
EditorModel provides a underlying data model for the editor view.  It will
provide events on data location updates, job completions etc., and provides
a series of function to transform a list of data locations into tables that
are easy to process in the GridView class.

The idea is that the main data-related functionality of the Editor class is
enclapsulated in this underlying model, and that the editor's components
(data grid, buttons etc.) simply listen to events on the model.
%}
classdef EditorModel < handle
    
    properties
        dlocs = [];
        dlocs_filtered = [];
        jobs = [];
        jobs_completed = [];
        action_queue = [];
        selected
        selected_values
        selected_vars
        all_vars
        var_editable = [true];
        modifiers = xylobium.dledit.model.Modifier.empty;
        
        filter_expression % a text string of matlab code to be evaluated for all dlocs
    end
    
    properties(Dependent)
        varlist
    end
    
    properties(Access=private)
        varlist_  = {'path'}
        timer_;
        action_list_delayed_timer_ = timer.empty;
    end
    
    events
        on_dloc_added
        on_dloc_removed
        
        on_varlist_changed
        on_var_changed
        
        on_job_done
        on_job_added
        
        on_action_queue_changed
        on_queue_execution_start
        on_queue_execution_end
        on_queue_job_done
        
        on_selection_changed
    end
    
    methods 
        function obj = EditorModel(data)
%              % we can only load objects supporting data location:
%             if ~isa(data, 'begonia.data_management.DataLocation') ...
%                     && ~isa(data, 'begonia.data_management.DataLocationAdapter')
%                 error('Data needs to be derived from DataCollection or DataLocationAdapter');
%             end

            obj.dlocs = data;
            obj.dlocs_filtered = data;
            obj.filter_expression = "true";
            
            % start timer to check job states:
            t = timer;
            obj.timer_ = t;
            
            t.TimerFcn = @obj.handleTimer;
            t.ExecutionMode = 'fixedDelay';
            t.Period = 1;
            start(t);
        end
        
        
        function delete(obj)
            stop(obj.timer_);
            delete(obj.timer_);
            
            stop(obj.action_list_delayed_timer_);
            delete(obj.action_list_delayed_timer_)
        end
        
        
        % timer to update the model's knowledge of background tasks that
        % have been completed since last check.  Enables firing of eve
        function handleTimer(obj, ~, ~)
            jobs_done_count = length(obj.jobs_completed);
            
            ongoing = [];
            finished = [];
            for i = 1:length(obj.jobs)
                job = obj.jobs(i);
                if(strcmp(job.job_handle.State, 'finished'))
                    finished = [finished job];
                else
                    ongoing = [ongoing job];
                end
            end
            
            obj.jobs_completed = [obj.jobs_completed finished];
            obj.jobs = ongoing;
            
            if jobs_done_count ~= length(obj.jobs_completed)
                notify(obj, 'on_job_done');
            end
        end
        
                
        % performas a job as a batch operation
        function doJob(obj, dloc, varlist, title, fcn)
            wbar = waitbar(0.1,'Starting batch job');
            job_handle = batch(fcn, 0, {});
            task = xylobium.dledit.model.BackgroundTask(job_handle, dloc, varlist);
            task.title = title;
            obj.jobs = [obj.jobs task];
            notify(obj, 'on_job_added');
            close(wbar)
        end
        
        
        % Saves a callback for later execution on main thread
        function enqueueAction(obj, title, callback, dloc, editor)
            action = xylobium.dledit.model.QueuedAction(...
                title, callback, dloc, editor);
            obj.action_queue = [obj.action_queue action];
            
            % as long as we are rapidly adding tasks, we want to stop the
            % timer from fiering the event:
            if isvalid(obj.action_list_delayed_timer_)
                stop(obj.action_list_delayed_timer_);
                delete(obj.action_list_delayed_timer_);
            end
            
            % if rapid addition of actions stop, this will fire:
            obj.action_list_delayed_timer_ = timer('StartDelay', 0.4 ...
                , 'ExecutionMode', 'singleShot');
            obj.action_list_delayed_timer_.TimerFcn ...
                = @(~,~) notify(obj, 'on_action_queue_changed');
            start(obj.action_list_delayed_timer_);
            
            %notify(obj, 'on_action_queue_changed');
        end
              
        
        % executes all currently queued callbacks on main thread (not a
        % batch operation). Store all errors for later inspection.
        function runQueue(obj)
            notify(obj, 'on_queue_execution_start');
            had_err = false;
            
            todo = obj.action_queue(~strcmp('ok', {obj.action_queue.status}) ...
                & ~strcmp('ERR', {obj.action_queue.status}));
            
            disp(['Queue has ' num2str(length(todo)) ' tasks' ]);

            for action = todo
                action.status = '>>>'; 
                notify(obj, 'on_action_queue_changed');
                try
                    action.start_time = datetime();
                    action.callback(action.dloc, obj, action.editor);
                    action.status = 'ok';
                    action.end_time = datetime();
                catch err
                    disp('Error during queue execution. Stored in model.action_queue_error')
                    action.err = err;
                    had_err = true;
                    action.status = 'ERR';
                    action.end_time = datetime();
                end
                notify(obj, 'on_queue_job_done');
            end
            %obj.action_queue =[];
            
            notify(obj, 'on_queue_execution_end');
            notify(obj, 'on_action_queue_changed');
            
            if had_err
               warning('NOTE: Errors during queue execution') 
            end
        end
        
        
        % clears the queue:
        function clearQueue(obj)
            obj.action_queue =[];
            notify(obj, 'on_action_queue_changed');
        end
        
        
        function v = get.varlist(obj)
            v = obj.varlist_;
        end
        
        
        function set.varlist(obj, v)
            % ensure varlist is horizontal:
            if size(v,1) > 1
                v = v';
            end
            
            % variables starting with a exlamation mark are editable:
            obj.var_editable = startsWith(v, '!');
            v_cleaned = repmat("", length(v), 1);
            for i =  1:length(v)
                chrs = v{i};
                if startsWith(v(i), '!')
                    v_cleaned(i) = string(chrs(2:end));
                else
                    v_cleaned(i) = string(chrs);
                end
            end
            
            
            obj.varlist_ = cellstr(v_cleaned');
            notify(obj, 'on_varlist_changed');
        end
        
        
        function all = get.all_vars(obj)
            vars = [obj.dlocs.saved_vars];
            vars = [vars,obj.modifiers.key];
            all = unique(vars);
        end
        
        
        function notifyChanged(obj, dloc, varname, data)
            evdata = xylobium.dledit.model.VarChangedEventData(dloc, varname, data);
            notify(obj, 'on_var_changed', evdata);
        end
        
        function mod = get_mod_with_varname(obj,varname)
            if isempty(obj.modifiers)
                mod = [];
            else
                mod = obj.modifiers(strcmp(varname, {obj.modifiers.key}));
                if ~isempty(mod)
                    mod = mod(1);
                end
            end
        end
        
        function save(obj, dloc, varname, data)
%             % check for transformer:
%             mod = obj.get_mod_with_varname(varname);
%             
%             if isempty(mod)
%                 dloc.save_var(varname, data);
%             else
%                 mod.onSave(dloc,data,obj);
%             end
            
            % check for transformer:
            if ~isempty(obj.modifiers)
                mods = obj.modifiers(strcmp(varname, {obj.modifiers.key}));
                if ~isempty(mods)
                    mod = mods(1);
                    if mod.override_save
                        data = mod.onSave(dloc, data, obj);
                    end
                end
            end
   
            dloc.save_var(varname, data);

            obj.notifyChanged(dloc, varname, data);
        end
        

        
        function data_ = load(obj, dloc, varname, use_mods)
            % if we are using a modifier, we want to apply it here and make
            % that responsible for outputting a format the table can
            % handle.  This means the value does not even have to read
            % anything from the dloc.
            
            if nargin < 4
                use_mods = true;
            end
            
            % find a modifier matching the key:
            mods = [];
            if ~isempty(obj.modifiers) && use_mods
                mods = obj.modifiers(string({obj.modifiers.key}) == varname);
            end
            
            if ~isempty(mods)
                % MODE 1 : get data using modifier:
                mod = mods(1);
                if dloc.has_var(varname) && ~mod.skip_load
                    data = dloc.load_var(varname);
                else
                    data = [];
                end
                data_ = mod.onLoad(dloc, data, obj);
            else
                
                % MODE 2 : get data using normal lookup
                varname = char(varname);
                data_ = [];

                if contains(varname,  {'.', '{', '}', '(', ')'})
                    data_ = eval(['data_.' varname]);
                else
                    try
                        if varname(1) == "?"
                            data_ = dloc.has_var(varname(2:end));
                        else
                            data_ = dloc.load_var(varname);
                        end
                    catch
                        if isprop(dloc, varname)
                            data_ = dloc.(varname);
                        end
                    end
                end

                if isa(data_, 'string')
                   data_ = char(data_); % uitable cannot display string..
                end

            end
        end
        
        
        function data = loadMultiple(obj, dlocs, vars)
            data = cell(length(dlocs),length(vars));
            for i = 1:length(dlocs)
                for j = 1:length(vars)
                    data{i,j} = obj.load(dlocs(i),vars{j});
                end
            end
        end
        
        
        function [tbl, vars] = getFullTable(obj)  
            % check filter works:
            use_filter = ~isempty(obj.dlocs);
            obj.dlocs_filtered = [];
            if use_filter
                try 
                    dloc = obj.dlocs(1); %#ok<NASGU>
                    output = eval(string(obj.filter_expression));
                    if ~islogical(output)
                        error("Output of filter must be a logical")
                    end
                catch err
                    use_filter = false;
                    msgbox("Filter syntax or output error: " + err.message + ". All data included." )
                end
            end
            
            wb = waitbar(0, "Loading data...");
            vars = obj.varlist;
            tbl = {};
            for r = 1:length(obj.dlocs)
                dloc = obj.dlocs(r);
                
                if use_filter
                    incl = eval(string(obj.filter_expression));
                    if ~incl; continue; end
                end
                obj.dlocs_filtered = [obj.dlocs_filtered dloc];
                
                row = arrayfun(@(var) obj.load(dloc, char(var)) , vars ...
                    , 'UniformOutput' , false);
                tbl = vertcat(tbl, row);
                waitbar(r/length(obj.dlocs), wb)
            end
            
            tbl = cell2table(tbl);
            if isempty(tbl)
                vars = replace(obj.varlist,'?','');
                tbl = cell2table(cell(0,length(vars)), "VariableNames", vars);
            else
                tbl.Properties.VariableNames = replace(obj.varlist,'?','');
            end
            
            delete(wb)
        end
        
        
        
        function [c,r] = getDlocVarIndex(obj, dloc, varname)
            c = [];
            for i = 1:length(obj.dlocs_filtered)
                if obj.dlocs_filtered(i) == dloc
                    c = i;
                    break;
                end
            end
            r = find(strcmp(obj.varlist, varname));
        end
        
        
        function select(obj, dlocs)
            obj.selected = dlocs;
            notify(obj, 'on_selection_changed');
        end
            
        
        function selectByIndicies(obj, indicies)
            % find vars and their datlocations:
            [vars, datalocs] = obj.varFromIndex(indicies);
            obj.selected_vars = string(vars);
            
            % find values for the vars
            obj.selected_values = obj.loadMultiple(datalocs, vars);
            
            % select dlocs (fires event)
            obj.select(datalocs);
        end
        
        
        function [vars, datalocs] = varFromIndex(obj, indicies)
            % find dataloctions from the indecies:
            rows = unique(indicies(:,1));
            datalocs = obj.dlocs_filtered(rows);
            
            % find the variables from the indicies:
            cols = unique(indicies(:,2));
            vars = obj.varlist(cols);
        end
        
    end
    
    

end