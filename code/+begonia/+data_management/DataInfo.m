classdef DataInfo < handle
    
    properties(Abstract)
        uuid
        name
        path
        type
        source
        
        start_time_abs
        duration
        time_correction
        
        
    end
    
    properties(Transient)
        start_time
        end_time
     
    end
    
    methods
        function obj = DataInfo
            obj.time_correction = duration(0,0,0);
            obj.start_time_abs = datetime([], [], [], [], [], []);
            obj.duration = duration([],[],[]);
        end
                
        function val = get.start_time(self)
            val = self.start_time_abs + self.time_correction;
        end
        
        function set.start_time(self,val)
            warning('start_time is a read only property. Setting start_time_abs instead.');
            if ~isempty(val)
                self.start_time_abs = val;
            end
        end
        
        function val = get.end_time(self)
            val = self.start_time + self.duration;
        end
        
        function set.end_time(~,~)
            error('end_time is a read only property.');
        end
    end
end

