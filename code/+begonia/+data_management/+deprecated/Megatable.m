%#ok<*PROPLC>
classdef Megatable < handle
    %MEGATABLE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        tabfile_path
        tab
        stash
        default_dt
        
        categories
        
        STASH_CAT = "megatable";
    end
    
    %% object methods
    
    methods
        
        function obj = Megatable(tabfile_path, stash, default_dt)
            obj.tabfile_path = string(tabfile_path);
            obj.default_dt = default_dt;
            obj.stash = stash;
            
            
            % load the table, or establish if it does not exist:
            if ~exist(tabfile_path, 'file')
                data_id = "_dummy"; 
                group_id = categorical("_id");
                category = categorical("_internal"); 
                updated = datetime();
                tags = "_system";  
                stash_url = "stash://_test"; 
                unit = "a.u.";
                delta_time = double(1/10000);
                meta = {struct()};
                
                obj.tab = table(data_id, group_id, category, updated, tags, stash_url, unit, delta_time, meta);
                obj.save();
            else
                imported = load(tabfile_path);
                obj.tab = imported.mtab;
            end
            
        end
        
        %% lists all categories stored in the table
        function cats = get.categories(obj)
            cats = unique(obj.tab.category);
            cats = cats(cats ~= "_internal");
        end
        
        %% removes all entrie sin a given category
        function clear_category(obj, category)
            obj.tab = obj.tab(obj.tab.category ~= category,:);
        end
        
        %% updates the megatable
        %function entry = update(obj, trace, namespace, subset, identifier, category, tags, unit, delta_time, start_offset, meta)
        function entry = update(obj, data, data_id, group_id, category, tags, unit, delta_time, resamp_strat, meta)
            if nargin < 9
                if isnumeric(data)
                    resamp_strat = "linear";
                elseif islogical(data)
                    resamp_strat = "nearest";
                end
            end
            if nargin < 10
                meta = {};
            end
            
            % stash the data if it is not a string (assuming stash url if so):
            if ~isa(data, 'string') 
                stash_url = obj.stash.put(obj.STASH_CAT, data_id, data);
            else
                stash_url = data;
            end
            
            group_id = categorical(string(group_id));
            category = categorical(category);
            updated = datetime();
            unit = categorical(unit);
            
            % validate that the trace is the correct dimentions and can be unstashed:
            data = obj.stash.get(stash_url);
            if size(data, 1) < size(data, 2)
                error("Traces has wrong dimentions! Pivot array. Data needs to be vertical, and a single column only.");
            end
            
            % table cannot be made by empty meta struct:
            if isempty(meta)
                meta = {struct()};
            end
            
            % create entry to insert into table:
            entry = table(data_id, group_id, category, updated, tags, stash_url, unit, delta_time, meta);
            
            % remove entry if it already exist:
            obj.tab = obj.tab(obj.tab.data_id ~= data_id,:);
            obj.tab = vertcat(obj.tab, entry);
        end
        
        %% saves the megatable changes to disk
        function save(obj)
            mtab = obj.tab; %#ok<NASGU>
            save(obj.tabfile_path, "mtab");
        end
        
        %% get traces by tag
        function [traces, t] = by_tag(obj, tag, dt, eqs_strat)
            traces = obj.tab(contains(obj.tab.tags, tag),:);
            if isempty(traces)
                return;
            end
            
            % unstash if asked:
            traces = obj.unstash(traces);
            [traces, len] = obj.resample_and_equisize(traces, dt, eqs_strat);
            t = seconds((1:len) * dt)';
        end
        
        %% gets all traces in a category:
        function [traces, t] = by_cat(obj, cats, dt, eqs_strat)
            % BY_CAT  Returns the row traces correstponding to one of the
            % categories.
            tab = obj.tab; 
            
            % filter by category and group:
            match_a_cat = arrayfun(@(c) any(c == cats), string(tab.category'));
            traces = tab(match_a_cat,:);

            traces = obj.unstash(traces);
            [traces, len] = obj.resample_and_equisize(traces, dt, eqs_strat);
            t = seconds((1:len) * dt)';
        end
        
        
        %% gets all traces with given group and category:
        function [traces, t] = by_group_and_cat(obj, group_ids, cats, dt, eqs_strat)
            tab = obj.tab;
            if ~isa(group_ids, string)
                group_ids = string(group_ids); % attempt conversion
            end
            
            % filter by category and group:
            match_a_cat = arrayfun(@(c) any(c == cats), string(tab.category'));
            traces = tab(match_a_cat,:);
            
            traces = traces(contains(string(traces.group_id'), group_ids),:);
            
            
            traces = obj.unstash(traces);
            [traces, len] = obj.resample_and_equisize(traces, dt, eqs_strat);
            t = seconds((1:len) * dt)';
        end
        
                
        %% grabs a single trace
        function [trace, row, len] = by_data_id(obj, data_id, dt, rettype, eqs_strat)
            if nargin < 4
                rettype = "trace";
            end
            
            row = obj.tab(obj.tab.data_id == data_id,:);
            if isempty(row)
                error("No such trace with identifier " + data_id);
            end
                
            if height(row) > 1
                error("Multiple traces with given identifier!");
            end
                
            row = obj.unstash(row);
            [row, len] = obj.resample_and_equisize(row, dt, eqs_strat);
            
            if rettype == "trace"
                trace = row.trace{:};
            elseif rettype == "entry"
                trace = row;
            end
        end   
        
        %% grabs all traces in a group
        function [rows, len] = by_group_id(obj, group_id, dt, eqs_strat)

            group_id = string(group_id);
            rows = obj.tab(obj.tab.group_id == group_id,:);
            
            if isempty(rows)
                error("No such group with identifier " + group_id);
            end
 
            rows = obj.unstash(rows);
            [rows, len] = obj.resample_and_equisize(rows, dt, eqs_strat);
        end
    end
    
    %% static functions
    
    methods(Static)
        
        % function to make tags parameters:
        function rows = tag_to_column(rows, tag, trans_func)
            tag = char(tag);
            vals = strings(height(rows), 1);
            for i = 1:height(rows)
                tag_data = rows{i,'tags'};
                params = begonia.util.param_string_to_dict(tag_data);
                if params.isKey(tag)
                    val = params(tag);
                    vals(i) = {val};
                end
            end
            
            
            if nargin > 2
                rows.(tag) = trans_func(vals);
            else
                rows.(tag) = vals;
            end
            
        end
        
        % removes rows from groups missing the given trace:
        function rows = remove_groups_without(rows, trace_cat)
            
            groups = string(unique(rows.group_id)');
            
            for group = groups
                group_rows = rows(rows.group_id == group,:);
                if ~contains(trace_cat, string([group_rows.category]))
                    rows = rows(rows.group_id ~= group,:);
                end
                
            end
            
        end
        
        % returns a table of episodes based on a binary trace:
        function tab_episodes = get_episodes(trace, dt)
            
            tab_episodes = table.empty;
            comps = bwconncomp(trace);

            if comps.NumObjects == 0
                return;
            end

            e = 1;
            for comp = comps.PixelIdxList
                episode_idx(e,:) = e;

                start_f(e,:) = comp{:}(1);
                end_f(e,:) = comp{:}(end); %#ok<*AGROW>
                duration_f(e,:) = end_f(e) - start_f(e) + 1;

                start_s(e,:) = start_f(e) * dt;
                end_s(e,:) = end_f(e) * dt;
                duration_s(e,:) = duration_f(e) * dt;

                e = e + 1;
                
%                 if comp{:}(end) == 8339
%                     warning("Weird one");
%                 end
            end

            tab_episodes = table(episode_idx, start_s, start_f, end_s, end_f, duration_s, duration_f);
        end
        
        % returns a table of episodes based on a binary trace:
        function tab_episodes = get_group_episodes(rows, use_cut, dt)
            import begonia.data_management.*;
            tab_episodes = table.empty;
            
            for i = 1:height(rows)
                
                if use_cut
                    trace = rows(i,:).trace_cut{:};
                else
                    trace = rows(i,:).trace{:};
                end
                
                %if rows(i,:).group_id == "TSeries-02012018-0653-047"
               % 	warning("Weird one");
               % end

                % collect the episodes from all the rows, and mark the
                % groups they belong to: 
                trace_episodes = Megatable.get_episodes(trace, dt);
                group_id = categorical(rows(i,:).group_id);
                
                trace_episodes.group_id = repmat(group_id, height(trace_episodes), 1);
                
                if ~isempty(trace_episodes)
                    tab_episodes = vertcat(tab_episodes, trace_episodes);
                end
            end
        end
        
        
        % gets a table of transitions from provided rows:
        function [trans_map, tab_trans, trans_idx] = get_transitions_by_classifier(...
                rows, trace_source, clf_cat, from, to, pre_take_dur, post_take_dur)
            
            import begonia.data_management.*;
            
            % ensure paramteres are categoricals:
            from = categorical(from);
            to = categorical(to);
            
            % we only accept durations to tell us how much data to take:
            if ~isduration(pre_take_dur) || ~isduration(post_take_dur)
                error("pre_take and post_take must be durations")
            end
            
            % check we have the right trace source:
            if trace_source == "filtered"
                trace_name = 'trace_cut';
            elseif trace_source == "raw"
                trace_name = 'trace';
            else
                error("trace_soure must be 'filtered' or 'raw'")
            end

            % calculate the left and right number of frames to catch:
            dt = rows(1,:).delta_time;
            left_f = seconds(pre_take_dur) / dt;
            right_f = seconds(post_take_dur) / dt;
            trans_idx = left_f + 1;
            
            % get all groups, and iterate over them, finding all timepoints
            % when the classifier trace goes from->to, and extract
            % corresponding duration. 
            groups = unique(rows.group_id)';
            tab_trans = table.empty;
            
            for group = groups
                % get the classifier trace and traces for this group:
                rows_grp = rows(rows.group_id == group,:);
                trace_cl = rows_grp(rows_grp.category == clf_cat,:).(trace_name);
                if isempty(trace_cl); warning("Group has no classifier and will be skipped :" + string(group) );
                    continue; 
                end 
                trace_cl = trace_cl{:};
                
                % skip the classifier trace:
                rows_grp = rows_grp(rows_grp.category ~= clf_cat,:);
                
                % get transitions:
                for i = 1:height(rows_grp)
                    trace = rows_grp(i,:).(trace_name);
                    tab_row_trans = Megatable.get_transitions_internal(trace{:}, trace_cl, from, to, left_f, right_f);
                    if isempty(tab_row_trans) 
                        continue; 
                    end
                    
                    % add data ID from the row:
                    tab_row_trans.trace_id = repmat(rows_grp(i,:).data_id, height(tab_row_trans), 1);
                    tab_row_trans.category = repmat(rows_grp(i,:).category, height(tab_row_trans), 1);
                    tab_row_trans.group_id = repmat(rows_grp(i,:).group_id, height(tab_row_trans), 1);
                    tab_row_trans.tags = repmat(rows_grp(i,:).tags, height(tab_row_trans), 1);
                    tab_row_trans.delta_time = repmat(rows_grp(i,:).delta_time, height(tab_row_trans), 1);

                    tab_trans = vertcat(tab_trans, tab_row_trans);
                    
                end
            end
            
            trans_map = begonia.util.map_from_table_by_cat(tab_trans, "category");
        end
        
        % grabs transitions form rows in a single
        function tab_tansitions = get_transitions_internal(trace_src, classifier_tr, from, to, left, right)
            import begonia.util.*;
            
            tab_tansitions = table.empty;
            next_change_f = double.empty;
            
            % find change points:
            a = classifier_tr(1:end-1);
            b = classifier_tr(2:end);
            change_points = find(a ~= b);
            correct_change = arrayfun(@(p) a(p) == from && b(p) == to, change_points);
            transpoints = change_points(correct_change)';
            
%             % find all transition frame  s in classification_trace
%             state = classifier_tr(1);
%             transpoints = [];
%             t_cnt = 1;
%             for i = 2:length(classifier_tr)
%                 next_state = classifier_tr(i);
%                 
%                 if next_state ~= state 
%                     % is this the state we are looking for?
%                     if state == from && next_state == to
%                         transpoints(t_cnt) = i - 1;
%                         t_cnt = t_cnt + 1;
%                     end
%                     state = next_state;
%                     
%                 end
%             end
            
            % build transition table from the points found:
            %rows = 1;
            trans_nr = zeros(length(transpoints),1);
            trans_timepoint_f = zeros(length(transpoints),1);
            next_change_f = zeros(length(transpoints),1);
            trace = cell(length(transpoints),1);
            
            for rows = 1:length(transpoints)
                t_idx = transpoints(rows);
                [trans_trace, paddleft, paddright] = extract_and_padd(trace_src, t_idx, left, right);
                
                trans_nr(rows,:) = rows;
                padded(rows,:) = [paddleft, paddright];
                trace(rows,:) = {trans_trace};
                trans_timepoint_f(rows,:) = t_idx;
                
                % count duration of states before and after:
                next = find(classifier_tr(t_idx+1:end) ~= classifier_tr(t_idx+1), 1, 'first');
                if isempty(next)
                    next_change_f(rows,:) = length(classifier_tr(t_idx+1:end));
                else
                    next_change_f(rows,:) = next;
                end
                
                %rows = rows + 1;
            end
            
            if length(transpoints) > 0 
                tab_tansitions = table(trans_nr, trans_timepoint_f, trace, next_change_f, padded); 
            end
        end

        
        
        % gets a table of episodes and their traces based on a classifier
        function [eps_map, tab_eps] = get_episodes_by_classifier(rows, trace_source, clf_cat, state, padd_durs)
            import begonia.data_management.*;
            
            % check we have the right trace source:
            if trace_source == "filtered"
                trace_name = 'trace_cut';
            elseif trace_source == "raw"
                trace_name = 'trace';
            else
                error("trace_soure must be 'filtered' or 'raw'")
            end
           

            % find groups and look separately for each group:
            groups = unique(rows.group_id)';
            
            ep_cnt = 1;
            for group = groups
                grp_rows = rows(rows.group_id == group,:);
                if height(grp_rows) == 1; error("Only one trace for " + string(group) + " - needs both a classifier and a data trace"); end
                
                clf_trace = grp_rows(grp_rows.category == clf_cat,:);
                if height(clf_trace) ~= 1; error("Too many of too few classifier traces found for " + string(group) + ". There must be exactly one trace with that category for each group_id."); end
                
                % get the traces without the classifier:
                grp_rows = grp_rows(grp_rows.category ~= clf_cat,:);
                
                % get classifier and episodes:
                clf_trace = clf_trace.(trace_name); 
                eps_trace = clf_trace{:} == state;
                
                % get episodes:
                clf_eps = Megatable.get_episodes(eps_trace, grp_rows(1,:).delta_time);
                
                % augment each episode with each trace:
                for i = 1:height(grp_rows)
                    row = grp_rows(i,:);
                    trace = row.trace{:};
                    for j = 1:height(clf_eps)
                        ep = clf_eps(j,:);
                        subtrace = trace(ep.start_f:ep.end_f);
                        category(ep_cnt,:) = row.category;
                        group_id(ep_cnt,:) = row.group_id;
                        data_id(ep_cnt,:) = categorical(row.data_id);
                        tags(ep_cnt,:) = row.tags;
                        eps(ep_cnt,:) = {table2struct(ep)};
                        subtraces(ep_cnt,:) = {subtrace};
                        ep_cnt = ep_cnt + 1;
                    end
                end
                
                
            end
            
            if ep_cnt - 1 == 0
                error("No epsiodes");
            end
            
            tab_eps = table(data_id, group_id, category, eps, subtraces, tags);
            tab_eps = horzcat( tab_eps, struct2table([eps{:}]));
            tab_eps.eps = [];
            eps_map = begonia.util.map_from_table_by_cat(tab_eps, "category");
        end
        
        
        
        
        % filters the given table by the provided filter
        function tab_f = filter(data, filters, logic)
            import begonia.data_management.*;
             
            filter = ...
                Megatable.merge_filter_traces(filters, logic);
            
            tab_f = data;

            % make sure every row is the length of the filter:
            for i = 1:height(data)
                trace = data(i,:).trace{:};
                
                if length(trace) > length(filter)
                    trace = trace(1:length(filter));
                else
                    % if shorter, we need to reduce the lenght of the
                    % filter:
                    diff = length(filter) - length(trace);
                    %trace(end:end+diff) = 0;
                    filter = filter(1:end-diff);
                end
           
                % perform the filtering operation:
                trace = trace(filter);
                traces_cut(i,:) = {trace};
            end 
            
            tab_f.trace_cut = traces_cut;
        end 
        
        
        % takes a cell array of logical vectors, and returns the logical
        % and of all those:
        function trace_filter = merge_filter_traces(filters, logic)
            
            
            % if more than one filter is given, we need to "and" them:
            if iscell(filters)
                
                % do nothing if only one filter:
                if length(filters) == 1
                    trace_filter = filters{1};
                    return;
                end
                
                % if several, they cannot be longer than the shortest:
                len_min = min(arrayfun(@(t) length(t{:}), filters));
                
                % start with first filter:
                trace_filter = filters{1};
                trace_filter = trace_filter(1:len_min);
                
                % join filtesr:
                for filter = filters(2:end)
                    
                    tr_filter = filter{:};
                    if ~islogical(tr_filter)
                        error("Filter cell array must contain only logical vectors"); 
                    end
                    
                    if logic == "and"
                        trace_filter = trace_filter & tr_filter(1:len_min);
                    elseif logic == "or"
                        trace_filter = trace_filter | tr_filter(1:len_min);
                    else
                        error("Logic must be 'and' or 'or'");
                    end
                end
                
            else
                error("Filters need to be a cell array of one or more logical vectors");
            end
            
            trace_filter = logical(trace_filter);
        end
    end
    
    %% private methods
    
    methods (Access=private)
        
        %% takes a entry out of the stash
        function tab = unstash(obj, tab)
            %{
            We need to unstash the traces, resample to dt and fill the
            empty edges with nans. To do this, we need to know the longest
            one.
            %}
            
            traces = arrayfun(@(t) obj.stash.get(t), [tab.stash_url], 'UniformOutput', false);
            tab.trace = traces;   
        end
        
        %% resamples data and makes the treaces the same length
        % handles resampling a set of traces to the same delta time, and
        % also ensuring the traces are no longer than the shortest trace
        % (after resampling):
        function [tab, len_max] = resample_and_equisize(~, tab, dt, eqs_strat)
            % mainly used for internal functions: 
            if eqs_strat == "skip"
               len_max = nan; 
               return
            end
            
             % resample all traces to requested delta time:
             resampled_traces = tab.trace;
             
             for i = 1:height(tab)
                 % get the source delta time - skip resampling if the trace
                 % is already on target dt:
                 trace_dt = tab(i,:).delta_time;
                 trace = tab(i,:).trace{:};
                 
                 valid_data = true;
                 if isnumeric(trace)
                     valid_data = ~all(isnan(trace));
                 end
                 
                 % resample using a timetable:
                 trace_t = (1:length(trace))' * trace_dt;
                 timetab = timetable(seconds(trace_t), trace);
                 
                 if trace_dt ~= dt && valid_data
                     % resample using linear interpolation by default, but
                     % change to "nearest" if trace is a logical. Remember
                     % the type so we can convert back afterwards, if so:
                     method = 'linear';
                     
                     % change method if logical or categorical:
                     non_numeric = islogical(trace) || iscategorical(trace);
                     if non_numeric 
                         method = 'nearest'; 
                         had_nans = false;
                     else
                         % if traces has nans, we need to resample those
                         % separately, which feels silly.. but have not
                         % found another way:
                         had_nans = any(isnan(trace));
                         if had_nans
                            nan_idxs = isnan(trace);
                            nan_timetab = timetable(seconds(trace_t), nan_idxs);
                            nan_timetab = retime(nan_timetab, 'regular', 'nearest', 'TimeStep', seconds(dt));
                         end
                     end
                         
                     timetab = retime(timetab, 'regular', method, 'TimeStep', seconds(dt));
                     
                     if non_numeric
                         trace = logical(trace); 
                     else
                        % re-fill nans that were present before interpolation
                        if had_nans
                            vars = timetab.Variables;
                            vars(nan_timetab.Variables) = nan;
                            timetab.Variables = vars;
                        end
                     end
                     
                     trace = timetab.trace;
                     resampled_traces{i} = trace;  
                 end
             end
            
            % replace the tabel's traces and delta time:
            tab.trace = resampled_traces;
            tab.delta_time = repmat(dt, height(tab), 1); 

            % cut all traces to be the same length:
            lengths = arrayfun(@(t) size(t{:}, 1), tab.trace);
            len_max = max(lengths);
            len_min = min(lengths);
            
            padded_traces = cell(height(tab), 1);
            org_length = zeros(height(tab), 1);

            if height(tab) > 1

                for i = 1:height(tab)
                    trace = tab(i,:).trace{:};
                     org_length(i) = length(trace);
                     
                    if eqs_strat == "pad"
                        f_diff = len_max - size(trace, 1);
                        trace = [trace; nan(f_diff, 1)];
                        padded_traces{i} = trace;
                    elseif eqs_strat == "trim"
                        padded_traces{i} = trace(1:len_min);
                    else
                        error("Bad equisize strategy. Final argument must be 'pad', or 'trim'");
                    end
                end

                tab.trace = padded_traces;
                tab.original_length = org_length;
            end
        end
        
        
    end
    
end

















