function tbl = var2table(data_locs,var,group_vars,skip_missing)
% Load the data under 'var' together with the grouping variables saved
% under 'group_vars'. The data saved under group_vars must be char. 

assert(ischar(var));
if nargin < 3
    group_vars = {};
end
if nargin < 4
    skip_missing = true;
end

if ischar(group_vars)
    group_vars = {group_vars};
end

tbls = cell(length(data_locs),1);

begonia.logging.backwrite();
for i = 1:length(data_locs)
    begonia.logging.backwrite(1,'loading ''%s'' %d/%d',var,i,length(data_locs));
    
    % Load the data under var.
    if skip_missing
        data = data_locs(i).load_var(var,[]);
        if isempty(data)
            continue;
        end
    else
        data = data_locs(i).load_var(var);
    end
    
    % Make data into a table. 
    if isstruct(data)
        data = struct2table(data,'AsArray',true);
    end
    if ischar(data)
        data = {data};
    end
    if ~istable(data)
        data = table(data,'VariableNames',{var});
    end
    
    % Load the grouping variables. 
    if ~isempty(group_vars)
        grps = cell(1,length(group_vars));
        for j = 1:length(group_vars)
            dat = data_locs(i).load_var(group_vars{j},'');
            if isempty(dat) && isprop(data_locs(i),group_vars{j})
                dat = data_locs(i).(group_vars{j});
            end
            grps{j} = dat;
        end
        grps = repmat(grps,height(data),1);
        grps = cell2table(grps,'VariableNames',group_vars);
        
        data = [grps,data];
    end
    
    tbls{i} = data;
end

tbl = cat(1,tbls{:});

% Make the grouping variables categorical.
if ~isempty(group_vars)
    for i = 1:length(group_vars)
        tbl.(group_vars{i}) = categorical(tbl.(group_vars{i}));
    end
end


end