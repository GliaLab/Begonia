function mat = window_transform(vec, window, spacing)

if nargin < 3
    spacing = window;
end

N = length(vec) - window + 1;
N = ceil(N/spacing);

mat = zeros(window, N);

for i = 1:N
    st = (i - 1) * spacing + 1;
    mat(:,i) = vec(st:st+window-1);
end

end

