function open_path_externally(path)

    if isfile(path)
        path = fileparts(path);
    end

    if isunix && ~ismac
        cmd = ['xdg-open "' path '" &'];
        %disp(['Opening external, linux style (fails - cut''n paste to console): ' newline cmd]);
        unix(cmd);
    elseif ispc
        %disp(['Opening external, Windows style: winopen("' path '")']);
        winopen(path);
    elseif ismac
        cmd = ['open "' path '" &'];
        %disp(['Opening external, macOS style: ' cmd]);
        system(cmd);
    end
    
end
