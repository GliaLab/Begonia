function roa_table = extract_roa_events(mat,dx,dy,dt)
if isempty(dx); dx = nan; end
if isempty(dy); dy = nan; end
if isempty(dt); dt = nan; end
%%
CC = bwconncomp(mat,6);
%%
roa_table = table;
roa_start_frame = zeros(CC.NumObjects,1);
roa_end_frame = zeros(CC.NumObjects,1);
roa_xy_area_pix = zeros(CC.NumObjects,1);
roa_volume_pix = zeros(CC.NumObjects,1);
roa_center = zeros(CC.NumObjects,3);

for i = 1:CC.NumObjects
    [y,x,t] = ind2sub(CC.ImageSize,CC.PixelIdxList{i});
    
    % Calculate the max x,y roa size. 
%     xy_size = unique([x,y],'rows');
%     xy_size = size(xy_size,1);
    % This method is the same as the commented lines above, but twice as
    % fast.
    xy_size = unique(y*(CC.ImageSize(2)+1)+x);
    xy_size = length(xy_size);
    
    roa_start_frame(i) = t(1);
    roa_end_frame(i) = t(end) + 1;
    roa_xy_area_pix(i) = xy_size;
    roa_volume_pix(i) = length(CC.PixelIdxList{i});
    roa_center(i,:) = round(mean([y,x,t],1));
end

roa_table = table(roa_start_frame,roa_end_frame,roa_xy_area_pix,roa_volume_pix,roa_center);
roa_table.roa_start = (roa_table.roa_start_frame - 1) * dt;
roa_table.roa_end = (roa_table.roa_end_frame - 1) * dt;
roa_table.roa_xy_area = roa_table.roa_xy_area_pix * dx * dy;
roa_table.roa_volume = roa_table.roa_volume_pix * dx * dy * dt;
roa_table.roa_duration = (roa_table.roa_end - roa_table.roa_start);

end

