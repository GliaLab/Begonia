function edit = edit(pos)
     if nargin < 1
           pos =  [20 20 150 20];
     end
    
    edit = uicontrol('Style', 'edit' ...
        , 'Position', pos ...
        , 'HorizontalAlignment', 'left');
end

