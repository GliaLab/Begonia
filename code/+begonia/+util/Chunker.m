classdef Chunker < handle 
    properties (SetAccess = private)
        mat
        chunks
        chunk_axis
        chunk_length
        chunk_size_mb
        chunk_padding
    end
    
    properties (Access = private)
        chunk_start_end
        padding_per_chunk
    end
    
    methods
        function self = Chunker(mat,varargin)
            % This is a weird way to get the first element in an array
            % which can usually  be done by just writing mat(1), but
            % because linear indexing has not been implemented for
            % begonia.util.H5Array we use this method which also works
            % other matrices. 
            I = num2cell(ones(1,ndims(mat)));
            first_element = mat(I{:});
            default_data_type = class(first_element);
            
            p = inputParser;
            p.addParameter('chunk_axis',ndims(mat),...
                @(x) validateattributes(x,{'numeric'},{'real'}));
            p.addParameter('chunk_size_mb',0,...
                @(x) validateattributes(x,{'numeric'},{'real'}));
            p.addParameter('chunk_length_RAM_fraction',4,...
                @(x) validateattributes(x,{'numeric'},{'real','integer'}));
            p.addParameter('chunk_length',[],...
                @(x) validateattributes(x,{'numeric'},{'real'}));
            p.addParameter('chunk_padding',0,...
                @(x) validateattributes(x,{'numeric'},{'real'}));
            p.addParameter('data_type',default_data_type,...
                @(x) begonia.util.validatestring(x,{'double','single','uint16','int16','uint8','int8'}));
            p.parse(varargin{:});
            begonia.util.dump_inputParser_vars_to_caller_workspace(p);
            
            if chunk_size_mb == 0
                % Get the memory of the computer to use as a default value for
                % chunk size. 
                if ismac 
                    [~,txt] = system('sysctl -a | grep hw.memsize | awk ''{print $2}'''); 
                    memory_avail_gb = (eval(txt)/1024^3);
                    memory_avail_mb = memory_avail_gb*1e3;
                    chunk_size_mb = memory_avail_mb/chunk_length_RAM_fraction;
                elseif ispc  
                    m = memory;
                    memory_avail_mb = m.MemAvailableAllArrays/1e6;
                    chunk_size_mb = memory_avail_mb/chunk_length_RAM_fraction;
                else
                    chunk_size_mb = 16000000/chunk_length_RAM_fraction;
                end
            end
            
            switch data_type
                % Find the bytes each number in mat.
                case 'double'
                    sample_size_bytes = 8;
                case 'single'
                    sample_size_bytes = 4;
                case 'uint16'
                    sample_size_bytes = 2;
                case 'int16'
                    sample_size_bytes = 2;
                case 'uint8'
                    sample_size_bytes = 1;
                case 'int8'
                    sample_size_bytes = 1;
                otherwise
                    error('Unknown byte size of the matrix class.');
            end
                
            dim = size(mat);
            dim(chunk_axis) = 1;
            slice_size = prod(dim)*sample_size_bytes;
            
            if isempty(chunk_length)
                % Base the chunk_length on the size of a slice of the data
                % along the chunk_axis and the desired chunk size in MB.
                chunk_length = round(chunk_size_mb*1e6/slice_size);
                chunk_length = max(chunk_length,1);
            else
                chunk_size_mb = chunk_length * slice_size / 1e6;
            end
            
            self.chunk_length = chunk_length;
            self.chunk_size_mb = chunk_size_mb;
            
            chunk_dim = size(mat,chunk_axis);
            
            chunk_start = 1:self.chunk_length:chunk_dim;
            chunk_end = circshift(chunk_start,-1) - 1;
            chunk_end(end) = chunk_dim;
            
            self.chunks = length(chunk_start);
            
            self.chunk_start_end = zeros(self.chunks,2);
            self.chunk_start_end(:,1) = chunk_start;
            self.chunk_start_end(:,2) = chunk_end;
            
            self.chunk_padding = chunk_padding;
            
            self.chunk_axis = chunk_axis;
            self.padding_per_chunk = zeros(self.chunks,2);
            self.padding_per_chunk(:,:) = chunk_padding;
            self.padding_per_chunk(1,1) = 0;
            self.padding_per_chunk(end,2) = 0;
            
            self.mat = mat;
        end
        
        
        function I = chunk_indices(self,chunk_number)
            I = repmat({':'},1,ndims(self.mat));
            idx_1 = self.chunk_start_end(chunk_number,1) - self.padding_per_chunk(chunk_number,1);
            idx_2 = self.chunk_start_end(chunk_number,2) + self.padding_per_chunk(chunk_number,2);
            I{self.chunk_axis} = idx_1:idx_2;
        end
        
        
        function I = chunk_indices_no_pad(self,chunk_number)
            I = repmat({':'},1,ndims(self.mat));
            idx_1 = self.chunk_start_end(chunk_number,1);
            idx_2 = self.chunk_start_end(chunk_number,2);
            I{self.chunk_axis} = idx_1:idx_2;
        end
        
        
        function mat = chunk(self,chunk_number)
            I = self.chunk_indices(chunk_number);
            mat = self.mat(I{:});
        end
        
        
        function mat = unpad(self,mat,chunk_number)
            otherdims = repmat({':'},1,ndims(self.mat));
            N = size(mat,self.chunk_axis);
            idx_1 = 1 + self.padding_per_chunk(chunk_number,1);
            idx_2 = N - self.padding_per_chunk(chunk_number,2);
            otherdims{self.chunk_axis} = idx_1:idx_2;
            mat = mat(otherdims{:});
        end
        
    end
    
end

