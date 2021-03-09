function [up, down] = consecutive_stages(logical_arr)
% consecutive_stages returns the start and stop indices for true elements.
%
%   [up,down] = consecutive_stages(logical_arr)
% 
%   logical_arr     - (1d logical array) Array of a stage at each element. 
%   up              - (1xN int) List of the first index for each
%                     consecutive episode where logical_arr == 1.
%   down            - (1xN int) List of the last index for each
%                     consecutive episode where logical_arr == 1.
%
is_row = isrow(logical_arr);
if ~is_row
    logical_arr = reshape(logical_arr,1,[]);
end

% Make sure the sequence has equally many up and down stages.
logical_arr = [0, logical_arr, 0];
diff_arr = diff(logical_arr);
up = find(diff_arr == 1)';
down = find(diff_arr == -1)' - 1;
assert(length(up) == length(down));

if ~is_row
    logical_arr = reshape(logical_arr,[],1);
end
end

