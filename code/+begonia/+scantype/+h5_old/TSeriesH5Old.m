classdef TSeriesH5Old < begonia.scantype.TSeries & ...
        begonia.data_management.DataLocation
    
    properties 
        uuid
        name
        type
        source
        
        start_time_abs
        duration
        time_correction
        
        cycles
        channels
        channel_names
        frame_count
        img_dim
        
        dx
        dy
        dt
        
        zoom
        frame_position_um
        
        files
    end
    
    methods
        function obj = TSeriesH5Old(path)
            if path(end) == filesep
                path(end) = [];
            end
            
            obj@begonia.data_management.DataLocation(path);
            
            obj.load_metadata();
        end
        
        function load_metadata(obj)
            
            metadata = obj.read_metadata();
            
            % Get the files of each cycle and channel.
            assert(isfield(metadata,'files'), ...
                'begonia:load:missing_struct_var', ...
                'metadata struct is missing ''files'' variable.');
            
            assert(~isempty(metadata.files), ...
                'begonia:load:empty_struct_var', ...
                'metadata struct has empty files var');
            
            obj.uuid = obj.dl_unique_id;
            
            obj.name                = metadata.name;
            obj.type                = 'TSeries';
            obj.source              = metadata.source;
            obj.channel_names       = metadata.channel_names;
            obj.channels            = metadata.channels;
            obj.dt                  = metadata.dt;
            obj.dx                  = metadata.dx;
            obj.dy                  = metadata.dx;
            obj.cycles              = metadata.cycles;
            obj.zoom                = metadata.optical_zoom;
            obj.duration            = metadata.duration;
            obj.frame_count         = metadata.frames_in_cycle;
            
            % workaround for older versions of the tseries metadata:
            if isfield(metadata, "start_time_abs") 
                obj.start_time_abs = metadata.start_time_abs;
            else
                obj.start_time_abs = metadata.start_time;
            end
            
            
            obj.start_time_abs.Format = 'uuuu/MM/dd HH:mm:ss';
            
            obj.files = cellfun(@(filename) fullfile(obj.path,filename), ...
                metadata.files, 'UniformOutput',false);
            
            dim = size(obj.get_mat(1));
            obj.img_dim = dim(1:2);
        end
        
        function metadata = read_metadata(self)
            metadata = begonia.scantype.h5_old.read_metadata(self.path);
        end
        
        function mat = get_mat(self,channel,cycle)
            if nargin < 3
                cycle = 1;
            end
            file = self.files{cycle,channel};
            mat = begonia.scantype.h5_old.h5arr(file);
        end
        
    end
    
end

