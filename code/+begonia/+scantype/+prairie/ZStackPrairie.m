classdef ZStackPrairie < begonia.scantype.ZStack ...
        & begonia.scantype.prairie.PrairieOutput

    properties
        files
        dz
    end
    
    methods
        function obj = ZStackPrairie(path)
            import begonia.scantype.prairie.*
            
            obj@begonia.scantype.prairie.PrairieOutput(path)
            
            % assert we are a linescan:
            assert(strcmp(obj.type, 'ZSeries'), ...
                    'begonia:load:not_zstack_sequence_type', ...
                    'Not a zstack according to type');
                
            obj.files = cellfun(@(filename) [obj.path,filesep,filename], ...
            obj.metadata.files, 'UniformOutput',false);
            
            files = obj.files(:);
            
            % generate the frame coordinates:
            xml = begonia.util.xml2struct(obj.xml_file);
            try
                frames = xml.PVScan.Sequence.Frame;
            catch
                error('begonia:load:no_frame_element', 'ZStack has no frame element');
            end
            
            assert(length(frames) > 1,  'begonia:load:insufficient_zstack_frames', 'ZStack has insufficient frames');
            
            for i = 1:length(frames)
                frame = frames{i};

                if ~isfield(frame.PVStateShard, 'PVStateValue')
                    obj.frame_position_um(i,1:3) = [nan nan nan];
                    continue; 
                end
                
                pos = get_struct_with_attrib(frame.PVStateShard.PVStateValue, "key", "positionCurrent");
                
                if isempty(pos)
                    obj.frame_position_um(i,1:3) = [nan nan nan];
                    continue; 
                end

                % X position
                x_stru = get_struct_with_attrib(pos.SubindexedValues, "index", "XAxis");
                x = str2double(x_stru.SubindexedValue.Attributes.value);


                % Y position
                y_stru = get_struct_with_attrib(pos.SubindexedValues, "index", "YAxis");
                y = str2double(y_stru.SubindexedValue.Attributes.value);


                % Z position
                z_stru = get_struct_with_attrib(pos.SubindexedValues, "index", "ZAxis");
                z_motor_stru = get_struct_with_attrib(z_stru.SubindexedValue, "description", "Z-Motor");
                z = str2double(z_motor_stru.Attributes.value);

                obj.frame_position_um(i,1:3) = [x y z];
            end
            
            % delta z:
            obj.dz = mode(obj.frame_position_um(3:end,3) - obj.frame_position_um(2:end-1,3));
            
            % fix first frame if it's position is nan:
            if isnan(obj.frame_position_um(1,1))
                obj.frame_position_um(1,1:3) = obj.frame_position_um(2,1:3);
                obj.frame_position_um(1,3) = obj.frame_position_um(2,3) - obj.dz;
            end
            
        end
        
         
        function mat = get_mat(self,cycle,channel)
            files = self.files(cycle,channel,:);  %#ok<*PROPLC>
            mat = begonia.frame_providers.PrarieFrameProvider(files);
        end
    end
end

