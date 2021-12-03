function editor = start(dlocs, custom_actions, vars)  
    import xylobium.dledit.mods.HasVarMod;
    
    if nargin < 3
        vars = dataman.get_default_vars();
    end
    if nargin < 2
        custom_actions = [];
    end
    if nargin < 1
        dlocs = begonia.data_management.DataLocation.empty;
    end

    actions = dataman.actions.build_menus_and_buttons();
    actions = [actions custom_actions];
    
    mods = xylobium.dledit.model.Modifier.empty;
    
    % preventing overload (literally!):
    mods(end+1) = HasVarMod("roi_table");
    mods(end+1) = HasVarMod("roa_mask");
    mods(end+1) = HasVarMod("roi_signals_dff");
    mods(end+1) = HasVarMod("roi_signals_rpa");
    
    mods(end+1) = begonia.processing.roa.ParamMod('roa_param');
    mods(end+1) = begonia.processing.roa.ParamMod('roa_pre_param');
    mods(end+1) = begonia.processing.roa.RoaPreFinished();
    mods(end+1) = begonia.processing.roa.RoaFinished();
    
    editor = dataman.Dataman(dlocs, actions, vars, mods);
    editor.filters = [...
        "true % NO FILTER" ...
        , "dloc.load_var('stabilized', false) == true % ONLY STABILIZED" ...
        , "dloc.load_var('stabilized', false) == false % ONLY NON-STABILIZED" ...
        , "dloc.has_var('roi_table') % ONLY ROI MARKED"...
        , "dloc.has_var('roa_finished') % ONLY ROA PROCESSED" ...
        , "dloc.has_var('compartment_signal') % ONLY ACTIVITY PROCESSED"...
        , "rand() > .5 % RANDOM SELECTION, 50% CHANCE TO INCLUDE" ...
        , "isa(dloc,'begonia.scantype.h5.TSeriesH5')"];
end

