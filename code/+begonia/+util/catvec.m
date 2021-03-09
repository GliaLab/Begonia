function vec = catvec(varargin)
vec = cell(varargin{:});
vec(:) = {''};
vec = categorical(vec);
end