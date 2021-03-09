function vec1_logical = align_indices(vec1_t, vec2_t, vec2_logical)
% Convert the logical array of vec_2 into a time aligned logical of vec_1.
% The output is a logical with the same length as vec1_t.

assert(length(vec2_t) == length(vec2_logical));

[st,en] = begonia.util.consecutive_stages(vec2_logical);

vec1_logical = zeros(size(vec1_t),'logical');
for i = 1:length(st)
    idx_2_st = st(i);
    idx_2_en = en(i);
    
    t_2_st = vec2_t(idx_2_st);
    t_2_en = vec2_t(idx_2_en);
    
    idx_1_st = begonia.util.val2idx(vec1_t, t_2_st);
    idx_1_en = begonia.util.val2idx(vec1_t, t_2_en);
    
    vec1_logical(idx_1_st:idx_1_en) = true;
end

end

