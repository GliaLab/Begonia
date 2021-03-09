function mat = dilate_logical(mat, N,side)
if nargin < 3
    side = 'both';
end

if isrow(mat)
    mat = mat';
    was_row = true;
else
    was_row = false;
end

for i = 1:size(mat,2)
    [u,d] = begonia.util.consecutive_stages(mat(:,i));
    
    switch side
        case 'both'
            u = u - N;
            d = d + N;
        case 'left'
            u = u - N;
        case 'right'
            d = d + N;
    end
    
    u = max(u,1);
    u = min(u,size(mat,1));
    
    d = max(d,1);
    d = min(d,size(mat,1));
    
    mat(:,i) = false;
    for j = 1:length(u)
        mat(u(j):d(j),i) = true;
    end
end

if was_row
    mat = mat';
end

end

