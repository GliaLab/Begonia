function [vec, enum] = to_loopable(vec)
    if size(vec, 1) > 1
        vec = vec';
    end
    
    % wishfull thinking ),:
    enum = 1:length(vec);
end

