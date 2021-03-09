function filter = gausswin(sigma,alpha)
% sigma - The distance in points from the center of the curve to 1 sigma.
% alpha - The distance in sigma from the center of the curve to the last point.

if nargin < 2
    alpha = 3;
end

% window size is equal to 1 + 2*round(alpha*sigma);

% The number of points included in the window. 
N = round(alpha*sigma);
if N <= 1
    filter = 1;
    return;
end
t = (-N:N)/sigma;

% Create the window. 
filter = exp(-(t.*t)/2);
% Normalize to ensure output is same scale after convolution.
filter = filter/sum(filter);

filter = filter';
end

