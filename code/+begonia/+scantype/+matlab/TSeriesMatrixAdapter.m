classdef TSeriesMatrixAdapter < begonia.scantype.TSeries & ...
        begonia.data_management.DataLocationAdapter
    
    properties
        cycles           	% defined in begonia.scantype.TSeries
        channels         	% defined in begonia.scantype.TSeries
        channel_names    	% defined in begonia.scantype.TSeries
        frame_count      	% defined in begonia.scantype.TSeries
        img_dim          	% defined in begonia.scantype.TSeries
        dx               	% defined in begonia.scantype.TSeries
        dy               	% defined in begonia.scantype.TSeries
        dt               	% defined in begonia.scantype.TSeries
        zoom             	% defined in begonia.scantype.TSeries
        frame_position_um	% defined in begonia.scantype.TSeries
        uuid             	% defined in begonia.data_management.DataInfo
        name             	% defined in begonia.data_management.DataInfo
        type             	% defined in begonia.data_management.DataInfo
        source           	% defined in begonia.data_management.DataInfo
        start_time_abs   	% defined in begonia.data_management.DataInfo
        duration         	% defined in begonia.data_management.DataInfo
        time_correction  
    end
    
    properties (Access=private)
        mat
        inner_ts
    end
    
    methods
        function obj = TSeriesMatrixAdapter(mat, src_ts)
            obj.mat = mat;
            obj.inner_ts = [];
            
            obj.uuid = begonia.util.make_uuid();
            obj.type = "Virtual TSeries";
            obj.source = "Matlab";
            obj.start_time_abs = datetime();
            obj.duration = seconds(size(mat, 3));
            obj.time_correction = 0;
            obj.cycles = 1;
            obj.frame_count = size(mat, 3);
            obj.img_dim = [size(mat, 1), size(mat, 2)];
            obj.dt = 1;
            obj.dx = 1;
            obj.dy = 1;
            obj.name = "Matlab matrix";
            obj.path = "./";
            obj.channels = 1;
            obj.channel_names = ["Virtual CH1"];
            obj.frame_position_um = [1 1 1];
            
            if nargin > 1
                obj.dt = src_ts.dt;
                obj.dx = src_ts.dx;
                obj.dy = src_ts.dy;
                obj.inner_ts = src_ts;
            end
        end
        
        function val = load_var(self, key, default)
            if isempty(self.inner_ts)
                %error("No inner TS in matrix adapter");
                val = default;
                return
            end
            
            if nargin == 3
                val = self.inner_ts.load_var(key, default);
            else
                val = self.inner_ts.load_var(key, default);
            end
        end
       
        
        function mat = get_mat(self,channel,cycle)
            mat = self.mat;
        end
        
        
        function img = get_max_img(self,channel,cycle)
            if nargin < 3; cycle = 1; end
            img = [];
            if ~isempty(self.inner_ts)
                img = self.inner_ts.get_max_img(channel, cycle);
            end
        end
        
        function img = get_std_img(self,channel,cycle)
            if nargin < 3; cycle = 1; end
            img = [];
            if ~isempty(self.inner_ts)
                img = self.inner_ts.get_std_img(channel, cycle);
            end
        end
        
        function img = get_avg_img(self,channel,cycle)
            if nargin < 3; cycle = 1; end
            
            img = [];
            if ~isempty(self.inner_ts)
                img = self.inner_ts.get_avg_img(channel, cycle);
            end
        end
    end
end

