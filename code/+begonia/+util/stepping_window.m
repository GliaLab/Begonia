function mat_out = stepping_window(mat,window,spacing,start_stop,data_class)

if nargin < 3 || isempty(spacing)
    spacing = window;
end

frames = size(mat,3);

if nargin < 4 || isempty(start_stop)
    start_stop = [1,frames];
end

if nargin < 5
    data_class = class(mat);
end

idx_start = start_stop(1);
idx_end = start_stop(2);

frames = idx_end - idx_start + 1;

N = frames - window + 1;
N = ceil(N/spacing);

dim = size(mat);

mat_out = zeros([dim(1),dim(2),N],data_class);

for i = 1:N
    offset = idx_start - 1;
    idx_1 = (i - 1) * spacing + 1 + offset;
    idx_2 = idx_1 + window - 1;
    mat_out(:,:,i) = mean(mat(:,:,idx_1:idx_2),3);
end

end

