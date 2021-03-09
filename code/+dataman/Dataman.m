classdef Dataman < xylobium.dledit.Editor
    %DATAMAN Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        session_file
        roiman
    end
    
    methods
        
        function obj = Dataman(dlocs, actions, vars, mods)
            obj@xylobium.dledit.Editor(dlocs, actions, vars, mods, false, true);
            obj.session_file = "";
            
            % will hold the open roi manager:
            obj.roiman = roiman.App.empty;
        end
        
    end
   
end

