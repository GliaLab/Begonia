function binary_mat_out = broaden_positives(binary_mat, dt, expansion)
    if isrow(binary_mat)
        binary_mat = binary_mat';
    end

    binary_mat_out = false(size(binary_mat));

    window = round(expansion/dt);

    x_end = size(binary_mat,1);

    for j = 1:size(binary_mat,2)
        for i = 1:size(binary_mat,1)
            if binary_mat(i,j)
                x1 = max(1,i-window);
                x2 = min(x_end,i+window);
                binary_mat_out(x1:x2,j) = true;
            end
        end
    end

end

