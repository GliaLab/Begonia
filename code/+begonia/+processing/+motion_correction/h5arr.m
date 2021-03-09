classdef h5arr
    % h5arr is a wrapper for h5create, h5read and h5info. 
    % % For new 5x5 array.
    % arr = h5arr(filename, [5,5])
    % arr = h5arr(filename, [5,5], 'uint16')
    %
    % % For reading exisitng h5arr
    % arr = h5arr(filename)
    
    %properties (SetAccess = private)
    properties
        filename
        dim
        datatype
    end
    
    methods
        function self = h5arr(varargin)
            p = inputParser;
            p.addRequired('filename')
            p.addOptional('dim', [])
            % "@(x) true" is there because strings are not accepted by
            % defualt as an optional argument. 
            p.addOptional('datatype', 'double', @(x) true)
            p.parse(varargin{:})
            in = p.Results;
            
            self.filename = in.filename;
            self.dim = in.dim;
            self.datatype = in.datatype;
            
            if isempty(self.dim)
                info = h5info(self.filename);
                %self.dim = info.Datasets(1).Dataspace.MaxSize;
                self.dim = info.Datasets(1).Dataspace.Size;
                % Read the first value and infer the type.
                s = struct;
                s.type = '()';
                s.subs = num2cell(ones(1,length(self.dim)));
                self.datatype = class(self.subsref(s));
            else
                if exist(self.filename,'file')
                    delete(self.filename);
                end
                h5create(self.filename,'/mov',self.dim, 'Datatype', in.datatype)
            end
        end
        
        function datatype = class(self)
            datatype = self.datatype;
        end
        
        
        function dim = size(self, i)
            if nargin < 2
                dim = self.dim;
            else
                dim = self.dim(i);
            end
        end
        
        function dim_length = ndims(self)
            dim_length = length(self.dim);
        end
        
        function self = subsasgn(self, s, data)
            if strcmp(s(1).type, '.')
                self = builtin('subsasgn',self,s,data);
                return
            end
            
            [start, count, stride] = self.get_scs(s);
            
            if length(data) == 1
                data = ones(count, self.datatype)*data;
            end
            
            h5write(self.filename,'/mov',data,start,count,stride)
        end
        
        function out = subsref(self, s)
            if strcmp(s(1).type, '.')
                out = builtin('subsref',self,s);
                return
            end
            
            [start, count, stride] = self.get_scs(s);
            out = h5read(self.filename,'/mov',start,count,stride);
            
            if length(s.subs) == 1 && ischar(s.subs{1})
                % If on the form h5arr(:) = data
                out = out(:);
            end
        end
        
        function [start, count, stride] = get_scs(self, s)
            start = zeros(1, length(self.dim));
            count = zeros(size(start));
            stride = ones(size(start));
            
            if length(s.subs) == 1 && ischar(s.subs{1})
                % If on the form h5arr(:) = data
                start(:) = 1;
                count = self.dim;
            else
                for i = 1:length(s.subs)
                    if ischar(s.subs{i})
                        % input is ':', write the whole dimension
                        start(i) = 1;
                        count(i) = self.dim(i);
                    else
                        % input is a list of indices. 
                        indices = s.subs{i};
                        
                        % Make sure the list is periodic.
                        unique_diffs = unique(diff(indices));
                        assert( length(unique_diffs) <= 1, 'h5arr requires indexing to be periodic.');
                        if length(unique_diffs) == 1
                            stride(i) = unique_diffs(1);
                        end
                        
                        start(i) = indices(1);
                        count(i) = length(indices);
                    end
                end
            end
            
            for i = 1:length(self.dim)
                assert(start(i) ~= 0, '(In this version) each dimension must be indexed.')
            end
        end
    end
    
end

