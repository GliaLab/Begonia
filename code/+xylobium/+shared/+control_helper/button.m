function button = button(text, cb, pos)
    if nargin < 3
       pos =  [20 20 80 120];
    end

    button = uicontrol('Style', 'pushbutton' ...
        , 'String', text' ...
        , 'Position', pos ...
        , 'Callback', cb);
end

