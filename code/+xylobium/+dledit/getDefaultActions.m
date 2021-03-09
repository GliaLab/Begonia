function actions = getDefaultActions()
    import xylobium.dledit.actions.*;
    import xylobium.dledit.*;

    % Data: reload

    
    % -- 
    % Data: open somehow:
    acOpenSomehow = Action('Open somehow'...
       , @(d, m, e) openSomehow(d, m, e), false, true, ".");
    acOpenSomehow.menu_position = "Data";
    
    acReload = Action('Reload'...
       , @(d, m, e) reload(d, m, e) ...
       , false, true, 'r');
    acReload.can_execute_without_dloc = true;
    acReload.menu_position = "Data";

    % ---
    % Data: send to workspace:
    acToWS = Action('To workspace'...
       , @(d, m, e) toWorkspace(d, m, e), false, true, "w");
    acToWS.menu_position = "Data";
    acToWS.menu_separator = true;

    % Data: as a table
    acToTab = Action('To table..'...
       , @(d, m, e) toTable(d, m, e), true, false, "t");
    acToTab.menu_position = "Data";

    % Data: as a table
    acToMat = Action('To matfile..'...
       , @(d, m, e) toMatfile(d, m, e), true, false, "m");
    acToMat.menu_position = "Data";

    % ---
    % Data: copy 1
    acCopy = Action('Copy single'...
       , @(d, m, e) copy_single(d, m, e), false, false, 'c');
    acCopy.menu_position = "Data";
    acCopy.menu_separator = true;
   
    % Data: past to all
    acPasteAll = Action('Paste to all'...
       , @(d, m, e) paste_to_all(d, m, e), false, true, 'v');
    acPasteAll.menu_position = "Data";
    
    % Data: clear
    acClear = Action('Clear selected'...
       , @(d, m, e) clearSelected(d, m, e), false, true);
    acClear.menu_position = "Data";
   
    % View : action queue
    acActionQueue = Action('Action queue'...
       , @(d, m, e) showQueue(d, m, e), false, true, '1');
    acActionQueue.can_execute_without_dloc = true;
    acActionQueue.menu_position = "View";

    % View : variable picker
    acVarPicker = Action('Variable picker'...
       , @(d, m, e) editVariables(d, m, e),...
       false, true, '2');
    acVarPicker.can_execute_without_dloc = true;
    acVarPicker.menu_position = "View";

    actions = [acOpenSomehow acReload ... 
        acToWS acToTab acToMat  ...
        acCopy acPasteAll acClear ...
        acActionQueue acVarPicker];

    % disable buttons for all:
    for action = actions; action.has_button = false; end
end

