% ViewModules implements layers of axis and other graphics handles in views
% (which hold a .figure property). 
classdef (Abstract) ViewModule < handle & matlab.mixin.Heterogeneous
    properties
        identifier
        name
    end
    
    methods
        function obj = ViewModule(name, identifier)
            obj.name = name;
            obj.identifier = identifier;
        end
        
        function on_init(obj, manager, view)
            warning("on_init :: not implemented for " + obj.name);
        end
        
        function on_enable(obj, manager, view)
            warning("on_enable :: not implemented for " + obj.name);
        end
        
        function on_disable(obj, manager, view)
            warning("on_disable :: not implemented for " + obj.name);
        end
        
        function on_update(obj, manager, view)
            warning("on_update :: not implemented for " + obj.name);
        end
    end
end

