classdef NoRMCorreConfigurator < handle
    %NORMCORRECONFIGURATOR Summary of this class goes here
    %   Detailed explanation goes here
    
    events
       on_save
       on_cancel
    end
    
    properties
        dialog
        settings
    end
    
    methods
        function obj = NoRMCorreConfigurator(settings)
            import xylobium.shared.control_helper.*;
            
            if nargin < 1 | isempty(settings)
                settings = begonia.processing.motion_correction.AlignmentSettings();
            end
            obj.settings = settings;
            
            % setup UX:
            obj.dialog = xylobium.shared.layout.RapidDialog();
            obj.dialog.title = "NoRMCorre configuration";
            
            obj.dialog.add('Rigid', checkbox(), 'logical');
            obj.dialog.add('Channel', edit(), 'double');
            obj.dialog.add('D1', edit(), 'double');
            obj.dialog.add('D2', edit(), 'double');
            obj.dialog.add('Bin width', edit(), 'double');
            obj.dialog.add('Overlap pre', edit(), 'double');
            obj.dialog.add('Overlap post', edit(), 'double');
            obj.dialog.add('Max shift', edit(), 'double');
            obj.dialog.add('Init batch', edit(), 'double');
            obj.dialog.add('Correct bidir', checkbox(), 'double');
            
            obj.dialog.choices = ["OK", "Cancel", "Reset"];
            obj.dialog.load_values(settings);
            
            addlistener(obj.dialog,'on_choice', @obj.handle_choice);
        end
        
        % handles user clicking an option:
        function handle_choice(obj, s, e)
            if e.choice == "OK"
                obj.dialog.save_values(obj.settings);
                notify(obj, 'on_save');
            elseif e.choice == "Cancel"
                obj.dialog.close();
                notify(obj, 'on_cancel');
            elseif e.choice == "Reset"
                obj.dialog.load_values(obj.settings);
            end
        end
        
    end
end





