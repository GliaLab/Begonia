function openDlocPath(dlocs, model, editor)
    for dloc = begonia.util.to_loopable(dlocs)
        dloc.open();
    end
end
