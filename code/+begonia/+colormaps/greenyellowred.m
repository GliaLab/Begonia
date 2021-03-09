function cmap = greenyellowred(samples)
if nargin < 1
    samples = 256;
end

red = [1,0,0];
yellow = [1,1,0];
green = [0,1,0];

X = 1:3';
V = [green;yellow;red];
Xq = linspace(1,3,samples);

cmap = interp1(X,V,Xq);

end

