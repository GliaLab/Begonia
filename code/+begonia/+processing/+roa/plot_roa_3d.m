function f = plot_roa_3d(roa_mask,dx,dy,dt)

y = (0:size(roa_mask,1)-1) * dy;
x = (0:size(roa_mask,2)-1) * dx;
z = (0:size(roa_mask,3)-1) * dt;
[X,Y,Z] = meshgrid(x,y,z);

f = figure;
p = patch(isosurface(X,Y,Z,roa_mask,0.5));

p.FaceColor = 'red';
p.EdgeColor = 'none';
% daspect([1 1 1])
view(3); 
axis tight
camlight 
lighting gouraud

xlabel('X (um)')
ylabel('Y (um)');
zlabel('Time (s)');

grid on

end

