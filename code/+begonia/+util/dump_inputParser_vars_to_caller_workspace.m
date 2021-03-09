function dump_inputParser_vars_to_caller_workspace(p)
% dump_inputParser_vars_to_caller_workspace loads inputParser variables to the callers workspace. 
% 
%   dump_inputParser_vars_to_caller_workspace(p)
%
%   p           - (inputParser object) inputParser
fields = fieldnames(p.Results);
for i = 1:length(fields)
    assignin('caller',fields{i},p.Results.(fields{i}));
end
end

