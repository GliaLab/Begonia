classdef H5Array
    % Example
%     mat = begonia.util.H5Array('test.h5',[3,3,3]);
%     mat = begonia.util.H5Array('test.h5',[3,3,3],'double','dataset_name','/asdf');
%     mat = begonia.util.H5Array('test.h5',[5,5,2],'single','dataset_name','/a/b');
%     mat = begonia.util.H5Array('test.h5',[3,2,3],'single','dataset_name','/a/a');
%     mat = begonia.util.H5Array('test.h5','dataset_name','/a/b');
% 
%     mat.fixed_dimensions(3) = 2;
%     mat(:,:) = reshape(1:5*5,5,5);
% 
%     mat.fixed_dimensions(3) = 0;
%     mat(:,:,:)
    
    properties
        filename
        dim
        fixed_dimensions
        datatype
        dataset_name
    end
    
    methods
        function self = H5Array(varargin)
            p = inputParser;
            p.addRequired('filename')
            p.addOptional('dim', [])
            p.addOptional('datatype','double', ...
                @(x)begonia.util.validatestring(x,{'double','single', ...
                'uint64','int64','uint32','int32','uint16','int16','uint8','int8'}));
            p.addParameter('dataset_name','/dataset1',@(x)validateattributes(x,{'char'},{'nonempty'}));
            p.addParameter('deflate',[],@(x)validateattributes(x,{'numeric'},{'nonempty','scalar','integer','>=',0,'<=',9}));
            p.addParameter('chunk_size',[]);
            p.parse(varargin{:})
            in = p.Results;
            
            self.filename = char(in.filename);
            self.dim = in.dim;
            self.datatype = in.datatype;
            self.dataset_name = in.dataset_name;
            
            if isempty(self.dim)
                info = h5info(self.filename,self.dataset_name);
                self.dim = info.Dataspace.Size;
                self.fixed_dimensions = zeros(1,length(self.dim));
                % Read the first value and infer the type. It looks weird
                % because indexing with linear values are not implemented.
                s = struct;
                s.type = '()';
                s.subs = num2cell(ones(1,ndims(self)));
                self.datatype = class(self.subsref(s));
            else
                % Create a new dataset.
                if ~isempty(in.deflate) && ~isempty(in.chunk_size)
                    h5create(self.filename,self.dataset_name,self.dim, ...
                        'Datatype',self.datatype, ...
                        'Deflate',in.deflate, ...
                        'ChunkSize',in.chunk_size);
                elseif ~isempty(in.deflate)
                    h5create(self.filename,self.dataset_name,self.dim, ...
                        'Datatype',self.datatype, ...
                        'Deflate',in.deflate);
                elseif ~isempty(in.chunk_size)
                    h5create(self.filename,self.dataset_name,self.dim, ...
                        'Datatype',self.datatype, ...
                        'Chunk_size',in.deflate);
                else
                    h5create(self.filename,self.dataset_name,self.dim, ...
                        'Datatype',self.datatype);
                end
                self.fixed_dimensions = zeros(1,length(self.dim));
            end
        end
        
        function self = set.fixed_dimensions(self,val)
            for i = 1:length(self.dim)
                assert(self.dim(i) >= val(i) && val(i) >= 0, ...
                    'Fixed dimensions outside array dimensions.');
            end
            self.fixed_dimensions = val;
        end
        
        function datatype = class(self)
            datatype = self.datatype;
        end
        
        function dim = size(self,i)
            dim = self.dim;
            % Remove the fixed dimensions.
            dim(self.fixed_dimensions ~= 0) = [];
            
            if nargin == 2
                dim = dim(i);
            end
        end
        
        function dim_length = ndims(self)
            dim_length = length(size(self));
        end
        
        function self = subsasgn(self, S, data)
            switch S(1).type
                case '.'
                    % Forward to the normal subsref function.
                    self = builtin('subsasgn',self,S,data);
                    return
                case '()'
                    assert(length(S) == 1,'Multiple levels of indexing not supported.')
                    assert(~isempty(S.subs), 'Invalid indexing');
                    
                    % Deal with the case to read everything as a column
                    % array.
                    if length(S.subs) == 1 && S.subs{1} == ':'
                        S.subs = repmat({':'},1,ndims(self));
                    end
                    
                    assert(length(S.subs) == ndims(self), ...
                        'All dimensions must be referenced when indexing with multiple subscripts.');
                    
                    % Insert fixed dimensions.
                    new_subs = cell(1,length(self.dim));
                    cnt = 0;
                    for i = 1:length(self.dim)
                        if self.fixed_dimensions(i)
                            new_subs{i} = self.fixed_dimensions(i);
                        else
                            cnt = cnt + 1;
                            new_subs{i} = S.subs{cnt};
                        end
                    end
                    S.subs = new_subs;
                    
                    % Find start, count and stride for reading H5.
                    start = zeros(1,length(self.dim));
                    count = zeros(1,length(self.dim));
                    stride = zeros(1,length(self.dim));

                    for i = 1:length(S.subs)
                        if strcmp(S.subs{i},':')
                            % Write the whole dimension.
                            start(i) = 1;
                            count(i) = self.dim(i);
                            stride(i) = 1;
                        else
                            % Input is a list of indices. 
                            I = S.subs{i};
                            
                            if islogical(I)
                                I = find(I);
                            end

                            % Check if the selection can be defined with a single
                            % stride value.
                            if length(I) > 1
                                strides = unique(diff(I));
                                assert(length(strides) == 1,'Selection cannot be defined with a single stride value. Consider indexing multiple times.');
                                stride(i) = strides(1);
                            else
                                stride(i) = 1;
                            end

                            start(i) = I(1);
                            count(i) = length(I);
                        end
                    end
                    
                    % Reshape the data to fit h5write.
                    if length(count) > 1
                        data = reshape(data,count);
                    end
                    
                    warning off
                    h5write(self.filename,self.dataset_name,data,start,count,stride)
                    warning on
                otherwise
                    error('Invalid indexing.')
            end
        end
        
        function out = subsref(self,S)
            switch S(1).type
                case '.'
                    % Forward to the normal subsref function.
                    out = builtin('subsref',self,S);
                    return
                    
                case '()'
                    assert(length(S) == 1,'Multiple levels of indexing not supported.')
                    assert(~isempty(S.subs), 'Invalid indexing');
                    
                    % Deal with the case to read everything as a column
                    % array.
                    if length(S.subs) == 1 && S.subs{1} == ':'
                        output_column = true;
                        S.subs = repmat({':'},1,ndims(self));
                    else
                        output_column = false;
                    end
                    
                    assert(length(S.subs) == ndims(self), ...
                        'All dimensions must be referenced when indexing with multiple subscripts.');
                    
                    % Insert fixed dimensions.
                    new_subs = cell(1,length(self.dim));
                    cnt = 0;
                    for i = 1:length(self.dim)
                        if self.fixed_dimensions(i)
                            new_subs{i} = self.fixed_dimensions(i);
                        else
                            cnt = cnt + 1;
                            new_subs{i} = S.subs{cnt};
                        end
                    end
                    S.subs = new_subs;
                    
                    % Find start, count and stride for reading H5.
                    start = zeros(1,length(self.dim));
                    count = zeros(1,length(self.dim));
                    stride = zeros(1,length(self.dim));

                    for i = 1:length(S.subs)
                        if S.subs{i} == ':'
                            % Write the whole dimension.
                            start(i) = 1;
                            count(i) = self.dim(i);
                            stride(i) = 1;
                        else
                            % Input is a list of indices. 
                            I = S.subs{i};
                            
                            if islogical(I)
                                I = find(I);
                            end

                            % Check if the selection can be defined with a single
                            % stride value.
                            if length(I) > 1
                                strides = unique(diff(I));
                                assert(length(strides) == 1,'Selection cannot be defined with a single stride value. Consider indexing multiple times.');
                                stride(i) = strides(1);
                            else
                                stride(i) = 1;
                            end

                            start(i) = I(1);
                            count(i) = length(I);
                        end
                    end
                    
                    out = h5read(self.filename,self.dataset_name,start,count,stride);
                    
                    % If some dimensions are fixed the output must be
                    % reshaped to remove the singleton dimension.
                    if any(self.fixed_dimensions)
                        % The new size is the size of the count argument of
                        % the dimensions that are not fixed.
                        new_size = count(~self.fixed_dimensions);
                        out = reshape(out,new_size);
                    end
                    
                    if output_column
                        out = out(:);
                    end
                otherwise
                    error('Invalid indexing.')
            end
                    
            %  This is an how to read individual samples. This feature is
            %  not implemented, but kept here because it was difficult to
            %  find documentation. I is an array if linear values, eg.g
            %  [1,2,6,3];
            
%             % Define the indices in the format h5 wants.
%             I = reshape(I,1,[]);
%             coords = cell(1,length(self.dim));
%             [coords{:}] = ind2sub(self.dim,I);
%             coords = cat(1,coords{:}) - 1;
%             coords = coords';
% 
%             % Open stuff
%             fid = H5F.open(self.filename); 
%             dset_id = H5D.open(fid,self.dataset_name);
%             file_space_id = H5D.get_space(dset_id);
% 
%             % Select
%             mem_space_id = H5S.create_simple(1,length(I),[]);           
%             h5_coords = fliplr(coords)';
%             H5S.select_elements(file_space_id,'H5S_SELECT_SET',h5_coords);
% 
%             % Read
%             out = H5D.read(dset_id,'H5ML_DEFAULT',mem_space_id,file_space_id,'H5P_DEFAULT');
% 
%             H5D.close(dset_id);
%             H5F.close(fid);
            
        end
        
    end
    
end

