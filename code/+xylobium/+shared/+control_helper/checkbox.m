function checkbox = checkbox(pos)
    if nargin < 3
       pos =  [20 20 20 20];
    end

    checkbox = uicontrol('Style', 'checkbox' ...
        , 'Position', pos);
end

