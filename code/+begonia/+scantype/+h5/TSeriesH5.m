classdef TSeriesH5 < begonia.scantype.TSeries & ...
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
    end
    
    methods
        function obj = TSeriesH5(path)
            if path(end) == filesep
                path(end) = [];
            end
            
            obj@begonia.data_management.DataLocation(path);
            
            obj.load_metadata();
        end
        
        function load_metadata(self)
            
            metadata = self.read_metadata();

            metadata.img_dim = reshape(metadata.img_dim,1,[]);
            
            self.uuid = self.dl_unique_id;
            
            self.channel_names      = metadata.channel_names;
            self.channels           = metadata.channels;
            self.img_dim            = metadata.img_dim;
            self.dt                 = metadata.dt;
            self.dx                 = metadata.dx;
            self.dy                 = metadata.dy;
            self.cycles             = metadata.cycles;
            self.zoom               = metadata.zoom;
            self.start_time_abs     = metadata.start_time;
            self.duration           = metadata.duration;
            self.frame_count        = metadata.frame_count;
            self.name               = metadata.name;
            self.source             = metadata.source;
            self.frame_position_um  = metadata.frame_position_um;
            
            self.frame_position_um = reshape(self.frame_position_um,1,[]);
            
            if ~isempty(self.start_time_abs)
                self.start_time_abs.Format = 'uuuu/MM/dd HH:mm:ss';
            end
            
            self.type = 'TSeries';
        end
        
        function metadata = read_metadata(self)
            metadata = begonia.scantype.h5.read_metadata(self.path);
        end
        
        function mat = get_mat(self,channel,cycle)
            if nargin < 3
                cycle = 1;
            end
            mat = begonia.util.H5Array(self.path,'dataset_name','/recording');
            mat.fixed_dimensions(3) = channel;
        end
        
    end
    
end

