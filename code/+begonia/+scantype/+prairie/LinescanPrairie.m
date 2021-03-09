classdef LinescanPrairie < begonia.scantype.Linescan ...
        & begonia.scantype.prairie.PrairieOutput

    properties
        first_point
        last_point
        line
        valid_data
        line_period
    end
    
    methods
        function obj = LinescanPrairie(path)
            obj@begonia.scantype.prairie.PrairieOutput(path);
          
            % assert we are a linescan:
            assert(strcmp(obj.type, 'Linescan'), ...
                    'begonia:load:not_linescan_sequence_type', ...
                    'Not a linescan according to type');
            try
                %obj.dt = obj.dt(1);
                %obj.dt = obj.metadata.lineperiod(2);
                obj.line_period = obj.metadata.line_period(2);
                obj.first_point = [obj.metadata.line_x(1) obj.metadata.line_y(1)];
                obj.last_point = [obj.metadata.line_x(end-2) obj.metadata.line_y(end-2)];
                obj.line =  [obj.metadata.line_x(:) obj.metadata.line_y(:)];
                obj.valid_data = true;
            catch e 
                e
                warning(['Path is linescan (has XML), but coukld not load linescan data :' path]);
                obj.valid_data = false;
                % TODO: should this raise error with begonia:load ?
            end
            
        end
        
        function mat = get_mat(obj, ~, channel)
            tifs = dir(fullfile(obj.path, '*.ome.tif'));
            paths = arrayfun(@(f) fullfile(f.folder, f.name), tifs, 'UniformOutput', false);
            if obj.cycles > 1
                error('LinescanPrairie *FIXME*: can only load when single cycle')
            else
                mat = imread(paths{channel});
            end
        end
        
    end
end

