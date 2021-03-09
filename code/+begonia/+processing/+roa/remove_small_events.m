function mat = remove_small_events(mat,min_size)

if min_size <= 1
    return;
end

CC = bwconncomp(mat, 4);
num_pixels = cellfun(@numel,CC.PixelIdxList);
idx = find(num_pixels < min_size);
for i = idx
    mat(CC.PixelIdxList{i}) = false;
end

end

