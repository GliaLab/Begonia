classdef PrarieFrameProvider
    %PRARIEFRAMEPROVIDER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = private)
        dim
        files
        output_class
    end
    
    methods
        function self = PrarieFrameProvider(files, output_class)
            if nargin < 2
               output_class = 'uint16';
            end
            
            self.output_class = output_class;
            self.files = files;
            
            img = imread(files{1});
            self.dim = [size(img), length(files)];
        end
        
        
        function type = class(self)
            type = self.output_class;
        end
        
        function out = subsref(self, s)
            if strcmp(s(1).type, '.')
                out = builtin('subsref',self,s);
                return
            end
            
            if length(s.subs) == 1 && ischar(s.subs{1})
                % If on the form 'mat(:)
                out = zeros(self.dim, self.output_class);
                for frame = 1:size(out,3)
                    out(:,:,frame) = imread(self.files{frame});
                end
            else
                % Handle each dimension indexing, eg. 'mat(:,1:3,:)'
                
                assert(length(s.subs) == 3, 'Unsupported indexing.');
                
                % First find out how many frames are selected, then use
                % builtin indexing on that matrix. 
                if ischar(s.subs{3})
                    % input is ':'
                    % return all frames. 
                    out = zeros(self.dim, self.output_class);
                    for frame = 1:size(out,3)
                        out(:,:,frame) = imread(self.files{frame});
                    end
                else
                    % input is a list of indices. 
                    frames = s.subs{3};
                    out = zeros([self.dim(1:2), length(frames)], self.output_class);
                    for i = 1:length(frames)
                        out(:,:,i) = imread(self.files{frames(i)});
                    end
                end
                
                % Send the first two indices to builtin and replace last
                % one with ':'.
                s.subs{3} = ':';
                out = builtin('subsref',out,s);
                
%                 % Handle each dimension indexing, eg. 'mat(:,1:3,:)'
%                 for i = 1:length(s.subs)
%                     if ischar(s.subs{i})
%                         % input is ':'
%                     else
%                         % input is a list of indices. 
%                     end
%                 end
            end
        end
        
        function dim = size(self, i)
            if nargin < 2
                dim = self.dim;
            else
                if i > ndims(self)
                    dim = 1;
                else
                    dim = self.dim(i);
                end
            end
        end
        
        function dim_length = ndims(self)
            dim_length = length(self.dim);
        end
    end
    
end

