%  Mementos keep editing actions in a stuctured manner that allows the user
%  to perform undo and redo when available.
classdef Memento < handle  
    
    properties
        max_undo
        history
        future
        
        has_undo
        has_redo
    end
    
    events
        on_availability_changed
        on_undo
        on_redo
    end
    
    methods
        function obj = Memento(max_undo)
            obj.max_undo = max_undo;
            obj.history = roiman.MementoAction.empty;
            obj.future = roiman.MementoAction.empty;
        end
        
        % "do" pushes a new action into history, or rather into the future
        % and then redoes it (for simplicity of code):
        function action = do(obj, func, desc, undo_func)
            if nargin > 3
                action = roiman.MementoAction(func, desc, undo_func);
            else
                action = roiman.MementoAction(func, desc);
            end
            
            % since a new action invalidates the existing future, we can
            % drop anything that was there. 
            obj.future = action;
            obj.redo();
            notify(obj, "on_availability_changed");
        end
        
        % "undo" pops one item from the last, calls the undo action, then
        % adds that action to the future in case the user changes their
        % mind about changing their mind (╯°□°)╯︵ ┻━┻
        function undo(obj)
            action = obj.history(end);
            obj.history = obj.history(1:end-1);
            obj.future = [obj.future ; action];
            action.undo_action();
            
            notify(obj, "on_undo");
            notify(obj, "on_availability_changed");
        end
        
        % "redo" pops the last element off future, and performs it, then adds
        % it to history.
        function redo(obj) 
            action = obj.future(end);
            obj.future = obj.future(1:end-1);
            obj.history = [obj.history ; action];
            action.edit_action();
            
            % if we have too many undos, we pull the first one off the
            % stack bottom:
            if length(obj.history) > obj.max_undo
                obj.history = obj.history(2:end);
            end
            
            notify(obj, "on_redo");
            notify(obj, "on_availability_changed");
        end
        
        function has = get.has_undo(obj)
            has = ~isempty(obj.history);
        end
        
        function has = get.has_redo(obj)
            has = ~isempty(obj.future);
        end
        
    end
end

