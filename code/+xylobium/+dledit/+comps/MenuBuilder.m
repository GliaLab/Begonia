classdef MenuBuilder < handle
    %MENUBUILDER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        editor
    end
    
    events
        on_action
        on_queue
    end
    
    methods
        function obj = MenuBuilder(editor)
            obj.editor = editor;
            obj.buildMenus(editor.actions)
        end
        
        
        % constructs the menubar based on events with menu positions:
        function buildMenus(obj, actions)
            is_menu = arrayfun(@(a) ~isempty(a.menu_position), actions);
            menu_actions = actions(is_menu);
            menus = unique([menu_actions.menu_position],'stable');

            for menu = menus
                fig = obj.editor.figure;
                in_current = arrayfun(@(a) a.menu_position == menu, menu_actions);

                mh = uimenu(fig, "text", menu);
                
                % get the items in this menu:
                for action = menu_actions(in_current)
                    obj.buildMenuItem(mh, action);
                end
            end
        end
        
        
        % constructs a menu item from an action and adds it to given menu
        function buildMenuItem(obj, menu, action)
            import xylobium.dledit.util.annotate_action_title;
            
            title = annotate_action_title(action);
            item = uimenu(menu, "text", title);
            item.Separator = action.menu_separator;
            item.MenuSelectedFcn = @(~, e) obj.handleMenuClick(e, action);

            try
                key = action.shortcut;
                if ~isempty(key); item.Accelerator = key; end
            catch 
                warning("Could not set shortcut for " + title + "- using legacy code? Update to be single key")
            end
        end
        
        
        % determines if a menu selection is made with shift key down so it
        % should be an action, not a queued action:
        function handleMenuClick(obj, ev, action)
            ev = xylobium.dledit.comps.ActionButtonEvent(action);
            if action.can_queue
                notify(obj, 'on_queue', ev);
            else
                notify(obj, 'on_action', ev);
            end
        end
        
    end
end

