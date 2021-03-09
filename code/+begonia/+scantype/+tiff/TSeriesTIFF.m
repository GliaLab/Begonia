classdef TSeriesTIFF < begonia.scantype.TSeries & ...
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
        function self = TSeriesTIFF(path)
            self@begonia.data_management.DataLocation(path);
            
            assert(~isfolder(path), ...
                'begonia:load:is_directory', ...
                'Input path is a directory. TSeriesTIFF only accepts .tif files.');
            
            self.load_metadata();
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
            
            if ~isempty(self.start_time_abs)
                self.start_time_abs.Format = 'uuuu/MM/dd HH:mm:ss';
            end
            
            self.type = 'TSeries';
        end
        
        function metadata = read_metadata(self)
            metadata = begonia.scantype.tiff.read_metadata(self.path);
        end
        
        function mat = get_mat(self,channel,cycle)
            warning off
            total_dirs = self.channels * self.frame_count;
            mat = TIFFStack(self.path,[],self.channels,true,total_dirs);
            mat.vnReducedDimensions = [0,0,channel,0,0];
            warning on
        end
        
        function mat = get_whole_mat(self)
            warning off
            total_dirs = self.channels * self.frame_count;
            mat = TIFFStack(self.path,[],self.channels,true,total_dirs);
            warning on
        end
    end
end

