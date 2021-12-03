classdef begonia_file_reader < Video_file_reader
    
    properties (Access = private)
        ts
        mats
    end
    
    properties
        current_frame = 0;
    end
    
    properties(GetAccess = public, Constant)
        datatype = 'BEGONIA';
    end
    
    methods
        function obj = begonia_file_reader(ts, buffer_size, bin_size)
            
            if nargin > 1 && ~isempty(buffer_size)
                obj.buffer_size = buffer_size;
            end
            if nargin > 2 && ~isempty(bin_size)
                obj.bin_size = bin_size;
            end
            
            obj.n_channels = ts.channels;
            obj.frame_count = ts.frame_count;
            obj.bitdepth = 16;
            obj.mat_data_type = 'int16';
            obj.frame_count = ts.frame_count;
            obj.current_frame = 0;
            
            obj.m = ts.img_dim(1);
            obj.n = ts.img_dim(2);
            
            for i = 1:ts.channels
                obj.mats{i} = ts.get_mat(i);
            end
        end
        
        function reset(obj)
            obj.current_frame = 0;
        end
        
        function buffer = read_batch(obj)
            if obj.current_frame > obj.frame_count
                buffer = [];
                return;
            end
            
            n_elem_left = min(obj.buffer_size * obj.bin_size, ...
                obj.frame_count - obj.current_frame);
            buffer = zeros(obj.m, obj.n, obj.n_channels, ...
                n_elem_left, obj.mat_data_type);
            
            for ch = 1:obj.n_channels
                mat = obj.mats{ch};
                buffer(:,:,ch,:) = mat(:,:,obj.current_frame+1:obj.current_frame+n_elem_left);
            end
            
            obj.current_frame = obj.current_frame + n_elem_left;
            
            if obj.bin_size > 1
                buffer = cast(convn(buffer, obj.downsampling_kernel, 'same'), obj.mat_data_type);
                buffer = buffer(:, :, :, ceil(obj.bin_size / 2):obj.bin_size:end);
            end
        end
        
        function buffer = read_frames(obj, idx)
            
            assert(sum(idx > obj.frame_count) == 0);
            
            n_elements = length(idx);
            
            buffer = zeros(obj.m, obj.n, obj.n_channels, n_elements, ...
                obj.mat_data_type);
            
            for ch = 1:obj.n_channels
                mat = obj.mats{ch};
                buffer(:,:,ch,:) = mat(:,:,idx);
            end
            
            if obj.bin_size > 1
                buffer = cast(convn(buffer, obj.downsampling_kernel, 'same'), obj.mat_data_type);
                if (obj.bin_size >= size(buffer, 4))
                    buffer = buffer(:, :, :, round(size(buffer, 4) / 2));
                else
                    buffer = buffer(:, :, :, ceil(obj.bin_size / 2):obj.bin_size:end);
                end
            end
        end
        
        function result = has_batch(obj)
            result = obj.current_frame < obj.frame_count;
        end
        
        function left = batches_left(obj)
            left = ceil((obj.frame_count - obj.current_frame) / ...
                (obj.buffer_size * obj.bin_size));
        end
        
        function close(obj)
            close(obj.tif);
        end
    end
end

