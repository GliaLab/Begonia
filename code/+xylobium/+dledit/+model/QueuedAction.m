classdef QueuedAction < handle
    %QUEUEDACTION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        title
        callback
        dloc
        editor
        status = 'pending'
        err
        
        queue_time
        start_time
        end_time
    end
    
    methods
        function obj = QueuedAction(title, callback, dloc, editor)
            if isstring(title)
                char(title);
            end
            obj.title = title;
            obj.callback = callback;
            obj.dloc = dloc;
            obj.editor = editor;
        end
    end
end

