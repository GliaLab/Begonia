function [vec, enum] = to_loopable(vec)
    if isempty(vec) 
        enum = [];
        return
    end

    if size(vec, 1) > 1
        vec = vec';
    end
    
    % wishfull thinking ),:
    enum = 1:length(vec);
end

