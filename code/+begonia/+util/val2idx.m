function idx = val2idx(arr, value)
% val2idx gives the index where a value closest matches an element in the input array. 
%
%   idx = val2idx(arr,value)
% 
%   arr             - (1-D numerical) input array.
%   value           - (numerical or 1-D numerical) value to find 
%                     index/indices of.
%   idx             - (numerical or 1-D numerical) index/indices where arr
%                     closest matches value.

if length(value) == 1
    [~, idx] = min(abs(arr - value));
else
    idx = zeros(size(value));
    for i = 1:length(value)
        [~, idx(i)] = min(abs(arr - value(i)));
    end
end

end

