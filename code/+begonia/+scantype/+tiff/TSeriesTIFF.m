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
        
        tiff_source
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
            self.frame_position_um  = metadata.frame_position_um;
            self.tiff_source        = metadata.tiff_source;
            
            if ~isempty(self.start_time_abs)
                self.start_time_abs.Format = 'uuuu/MM/dd HH:mm:ss';
            end
            
            self.type = 'TSeries';
        end
        
        function metadata = read_metadata(self)
            metadata = begonia.scantype.tiff.read_metadata(self.path);
        end
        
        function mat = get_mat(self,channel,cycle)
            if strcmp(self.tiff_source,'Sutter')
                % Sutter tiffs cannot be read by the lazy TIFFStack.
                tif = Tiff(self.path);
                mat = zeros([self.img_dim,self.frame_count],'uint16');
                
                % Read the first frame.
                for ch = 1:channel-1
                    tif.nextDirectory();
                end
                mat(:,:,1) = tif.read();
                
                % Read the rest.
                for i = 2:size(mat,3)
                    for ch = 1:self.channels
                        tif.nextDirectory();
                    end
                    mat(:,:,i) = tif.read();
                end
            else
                warning off
                total_dirs = self.channels * self.frame_count;
                % Use the modified version of the TIFFStack library to
                % input how many frames is contained in the tiff to avoid
                % reading unecessary header information. 
                mat = TIFFStack(self.path,[],self.channels,true,total_dirs);
                % Another modification to the TIFFStack library which
                % allows reducing the number of dimensions. Here we put
                % which channel should be fixed. This can change
                % dimensions from 4D (x,y,channel,frames) to 3D (x,y,frames).
                mat.vnReducedDimensions = [0,0,channel,0,0];
                warning on
            end
        end
    end
end

