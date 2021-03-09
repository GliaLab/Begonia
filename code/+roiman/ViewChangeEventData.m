classdef ViewChangeEventData < event.EventData & handle

    properties
        from
        to
        viewmanager
        viewmanager_changed
    end
end

