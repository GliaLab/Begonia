function cmap = linspaced(samples,varargin)

V = cat(1,varargin{:});
X = 1:size(V,1);
Xq = linspace(1,size(V,1),samples);

cmap = interp1(X,V,Xq);

end

