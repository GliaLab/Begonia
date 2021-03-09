function cmap = bluewhitered(samples)
if nargin < 1
    samples = 256;
end

blue = [0,0,1];
white = [1,1,1];
red = [1,0,0];

X = 1:3';
V = [blue;white;red];
Xq = linspace(1,3,samples);

cmap = interp1(X,V,Xq);

end

