classdef PrairieOutput < handle ...
        & begonia.data_management.DataLocation ...
        & begonia.data_management.DataInfo 
    
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
        
        rasters_pr_frame
        
        xml_file
        files
    end
    
    methods
        function obj = PrairieOutput(path)
            if path(end) == filesep
                path(end) = [];
            end
            
            if isstring(path)
                path = char(path);
            end
            
            obj@begonia.data_management.DataLocation(path);
            
            assert(exist(fullfile(path,'References'),'dir') == 7, ...
                'begonia:load:missing_Ref_folder', ...
                '''References'' folder not found, used as an indicator for PrarieOutput.');
            
            obj.load_metadata();
        end
        
        function metadata = read_metadata(self)
            % Try to guess the name of the xml file to avoid searching the
            % directory for it. 
            [~,dir] = fileparts(self.path);
            xml_file = fullfile(self.path,[dir,'.xml']);
            if ~exist(xml_file,'file')
                xml_files = begonia.path.find_files(obj.path,'.xml',false);
                if isempty(xml_files)
                    xml_file = '';
                else
                    xml_file = xml_files{1};
                end
            end

            metadata = begonia.scantype.prairie.read_metadata(xml_file);
        end
        
        function load_metadata(obj)
            obj.uuid = obj.dl_unique_id;
            
            metadata = obj.read_metadata();
            assert(~isempty(metadata),'begonia:load:missing_xml','Missing xml file.');

            switch metadata.type
                case 'Linescan'
                    type = 'Linescan';
                    start_time = metadata.start_time;
                    dur = seconds(metadata.relative_times(end)+metadata.line_period(end)*metadata.linesPerFrame(end));
                case 'TSeries Timed Element'
                    type = 'TSeries';
                    start_time = metadata.start_time;
                    dur = seconds(metadata.frames_in_cycle(1)*metadata.dt(1));
                case 'ZSeries'
                    type = 'ZSeries';
                    start_time = metadata.start_time;
                    dur = seconds(metadata.relative_times(end)+metadata.dt(1));
                case 'Single'
                    type = 'Single';
                    start_time = metadata.start_time;
                    dur = seconds(metadata.dt(1));
            end
            dur.Format = 'hh:mm:ss.SSS';

            obj.source = 'Prairie';
            obj.type = type;
            obj.rasters_pr_frame = metadata.rasters_pr_frame;
            obj.dx = metadata.dx;
            obj.dy = metadata.dx;
            obj.dt = metadata.dt(1);
            obj.zoom = metadata.optical_zoom;
            obj.cycles = metadata.cycles;
            obj.frame_count = metadata.frames_in_cycle(1);
            obj.duration = dur;
            obj.start_time_abs = start_time;
            obj.channels = metadata.channels;
            obj.channel_names = metadata.channel_names;
            obj.img_dim = metadata.img_dim; 
            obj.frame_position_um = metadata.frame_position_um;

            % Use the name of the xml file as the name of the TSeries.
            [~,name,~] = fileparts(metadata.xml_file);
            obj.name = name;
            obj.xml_file = fullfile(obj.path, [name,'.xml']);
            
            

            obj.files = cellfun(@(filename) [obj.path,filesep,filename], ...
                metadata.files, 'UniformOutput',false);
            
            files = obj.files(:);
            assert(~isempty(files),'begonia:load:empty_xml','The xml file has no tif files.');
            assert(exist(files{end},'file') == 2,'begonia:load:missing_tiffs','Missing tiff files!');
        end
    end
end

