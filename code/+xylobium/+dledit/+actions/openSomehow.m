function openSomehow(dlocs, model, editor)
% it's a bird, it's a plane, it's a...

things = model.selected_values;

for i = 1:numel(things)
    try
        path = things{i};
        if exist(path, 'dir') || exist(path, 'file')
            begonia.util.open_path_externally(path);
        end
    end
end

if numel(things) == 1
    things{1}
else
    model.selected_values
end
warning off
begonia.util.putvar('ans')
warning on
%     for i = 1:length(things)
%         thing = things{i};
%         if isstruct(thing)
%             thing
%             continue;
%         end
% 
%         if isa(thing, 'rig.sup.DataLocation')
%             rig.gui.DataViewer(thing, [], {'Name', 'Path'});
%             return;
%         end
% 
%         % dir's open externally
%         class(thing)
% 
%         try
%             path = char(thing);
%             if exist(path, 'dir') || exist(path, 'file')
%                 path
%                 begonia.util.open_path_externally(path)
%                 continue;
%             end
%         catch
% 
%         end
% 
%         % everything else we just dump:
%         thing
%     end
end




% function open_external(path)
% 
%     if isunix && ~ismac
%         cmd = ['xdg-open "' path '" &'];
%         disp(['Opening external, linux style (fails - cut''n paste to console): ' newline cmd]);
%         unix(cmd);
%     elseif ispc
%         disp(['Opening external, Windows style: winopen("' path '")']);
%         winopen(path);
%     elseif ismac
%         cmd = ['open "' path '" &'];
%         disp(['Opening external, macOS style: ' cmd]);
%         system(cmd);
%     end
% end
