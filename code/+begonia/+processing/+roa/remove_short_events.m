function mat = remove_short_events(mat,min_frames)
if min_frames <= 1
    return;
end

CC = bwconncomp(mat,6);
for i = 1:CC.NumObjects
    [x,y,t] = ind2sub(CC.ImageSize,CC.PixelIdxList{i});
    if length(unique(t)) < min_frames
        mat(CC.PixelIdxList{i}) = false;
    end
end

end

