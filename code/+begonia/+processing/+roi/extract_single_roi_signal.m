function vec = extract_single_roi_signal(roi, mat, mask)

    if nargin < 3
        mask = roi.mask;
    end

    % determine edges of mask:
    fx = find(sum(mask, 1) > 0, 1, 'first');
    fy = find(sum(mask, 2) > 0, 1, 'first');
    tx = find(sum(mask, 1) > 0, 1, 'last');
    ty = find(sum(mask, 2) > 0, 1, 'last');
  
    % calculate the average signal in each frame:
    area = sum(mask(:));
    % Cast mask to the same type as the input matrix. Because the matrix is
    % often lazy we first read the first value.
    mask = cast(mask,'like',mat(1,1,1));
    
    % for speed and memory, minimize the part of the matrix to use:
    mat_roi = mat(fy:ty, fx:tx,:) .* mask(fy:ty, fx:tx);
    
    % average = sum / area (observed pixels):
    vec = sum(sum(mat_roi,2), 1) ./ area;
    vec = squeeze(vec)';
end

