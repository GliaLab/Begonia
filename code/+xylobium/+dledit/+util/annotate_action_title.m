function title = annotate_action_title(action)
    title = action.title;
    if ~action.can_execute_without_dloc
        mark = "";
        if action.can_queue; mark = mark + "ᵇ"; end
        if action.accept_multiple_dlocs; mark = mark + "ᵐ"; end
        if mark ~= ""; mark = " ⁽" + mark + "⁾"; title = title + mark; end
    end
end

