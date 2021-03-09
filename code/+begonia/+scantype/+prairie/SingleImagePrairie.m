classdef SingleImagePrairie < begonia.scantype.SingleImage ... 
        & begonia.scantype.prairie.PrairieOutput
    
    properties
        frame_position_um
    end
    
    methods
        function obj = SingleImagePrairie(path)
            obj@begonia.scantype.prairie.PrairieOutput(path);
            
            assert(strcmp(obj.type, 'Single'), ...
                    'begonia:load:not_single_sequence_type', ...
                    'Not a single according to type');   
        end

        
        function mat = get_mat(obj, ~, channel)
            tifs = dir(fullfile(obj.path, '*.ome.tif'));
            paths = arrayfun(@(f) fullfile(f.folder, f.name), tifs, 'UniformOutput', false);
            if obj.cycles > 1
                error('SingleImagePrairie *FIXME*: can only load when single cycle')
            else
                mat = imread(paths{channel});
            end
        end
        
        function pos = get.frame_position_um(obj)
            import begonia.scantype.prairie.*;
            pos = get_coordinate_from_tsxml(obj.xml_file);
        end
    end
end

