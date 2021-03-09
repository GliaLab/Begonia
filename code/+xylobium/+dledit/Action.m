classdef Action < handle
    %EDITORACTION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        title
        click_callback
        button
        can_queue
        can_execute_without_dloc % for buttons that do not use the dlocs
        accept_multiple_dlocs
        reload_on_execute
        shortcut
        
        menu_position
        menu_separator
        
        has_button
        button_group
    end
    
    methods
        function obj = Action(title, clickcb, can_queue, accept_multiple_dlocs, shortcut)
            if nargin < 5
                shortcut = [];
            end
            
            if nargin < 4
                accept_multiple_dlocs = false;
            end
            
            if nargin < 3
                can_queue = false;
            end
            
            obj.title = title;
            obj.click_callback = clickcb;
            obj.can_queue = can_queue;
            obj.accept_multiple_dlocs = accept_multiple_dlocs;
            obj.shortcut = shortcut;
            
            obj.menu_position = string.empty;
            obj.menu_separator = false;
            
            obj.can_execute_without_dloc = false;
            
            obj.has_button = true;
            obj.button_group = "";
            obj.reload_on_execute = false;
        end
    end
end

