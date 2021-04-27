function actions = build_menus_and_buttons()
    % file menu:
    actions = [...
        file_menu() ...
        tools_menu() ...
        roi_menu() ...
        roa_menu()];    
end


function actions = get_recents() 
    import xylobium.dledit.Action;
    import dataman.actions.file.*;
    import dataman.support.*,
    import begonia.util.to_loopable;

    actions = xylobium.dledit.Action.empty;
    
    sessions = read_prefs("sessions", []);
    if isempty(sessions)
        return;
    end
    
    for file = to_loopable(sessions)
        if ~exist(file, "file")
            continue
        end
        [~,name] = fileparts(file);
        
        ac = Action(name, @(d, m, e) load_session(d, m, e, file), false, true);
        ac.menu_position = "File";
        ac.accept_multiple_dlocs = false;
        ac.can_execute_without_dloc = true;
        
        actions = [actions ac];
        if length(actions) > 0
            actions(1).menu_separator = true;
        end
    end
end


% constructs the file menu:
function actions = file_menu() 
    import xylobium.dledit.Action;
    import dataman.actions.file.*;
    
    ac_new = Action("New session", @new_session, false, true, "n");
    ac_new.menu_position = "File";
    ac_new.accept_multiple_dlocs = false;
    ac_new.can_execute_without_dloc = true;
    
    ac_new_from_selection = Action("New session from selection", @new_from_selection, false, true);
    ac_new_from_selection.menu_position = "File";
    ac_new_from_selection.accept_multiple_dlocs = true;
    ac_new_from_selection.can_execute_without_dloc = false;
    
    ac_add_file = Action("Add file...", @add_file, false, true, "a");
    ac_add_file.menu_position = "File";
    ac_add_file.accept_multiple_dlocs = false;
    ac_add_file.can_execute_without_dloc = true;
    ac_add_file.menu_separator = true;
    
    ac_add = Action("Add directory...", @add, false, true, "a");
    ac_add.menu_position = "File";
    ac_add.accept_multiple_dlocs = false;
    ac_add.can_execute_without_dloc = true;

    ac_rem = Action("Remove selected", @remove_selected, false, true, "d");
    ac_rem.menu_position = "File";
    ac_rem.accept_multiple_dlocs = true;
    ac_rem.can_execute_without_dloc = false;
    ac_rem.menu_separator = false;
    
    ac_loadcat = Action("Load Session...", @load_session, false, true, "k");
    ac_loadcat.menu_position = "File";
    ac_loadcat.menu_separator = true;
    ac_loadcat.accept_multiple_dlocs = false;
    ac_loadcat.can_execute_without_dloc = true;
    
    ac_loadlast = Action("Re-open Last", @load_last, false, true, "l");
    ac_loadlast.menu_position = "File";
    ac_loadlast.menu_separator = false;
    ac_loadlast.accept_multiple_dlocs = false;
    ac_loadlast.can_execute_without_dloc = true;
    
    ac_savecat = Action("Save Session", @(d, m, e) save_session(d, m, e, false), false, true, "s");
    ac_savecat.menu_position = "File";
    ac_savecat.menu_separator = true;
    ac_savecat.accept_multiple_dlocs = false;
    ac_savecat.can_execute_without_dloc = true;
    
    ac_savecatas = Action("Save Catalogue As...", @(d, m, e) save_session(d, m, e, true), false, true);
    ac_savecatas.menu_position = "File";
    ac_savecatas.accept_multiple_dlocs = false;
    ac_savecatas.can_execute_without_dloc = true;
    
    ac_exp = Action("Export selected...", @(d, m, e) dataman.export.wizard(d), false, true, "e");
    ac_exp.menu_position = "File";
    ac_exp.menu_separator = true;
    ac_exp.accept_multiple_dlocs = true;
    ac_exp.can_execute_without_dloc = false;

    ac_quit = Action("Quit", @quit, false, true, "q");
    ac_quit.menu_position = "File";
    ac_quit.menu_separator = true;
    ac_quit.accept_multiple_dlocs = false;
    ac_quit.can_execute_without_dloc = true;
    
    actions = [ac_new ac_new_from_selection ac_add_file ac_add  ...
        ac_rem ...
        ac_loadcat ac_loadlast ac_savecat ac_savecatas ...
        ac_exp ...
        get_recents()  ...
        ac_quit];
    
    for action = actions; action.has_button = false; end
end

% constructs the tools menu:
function actions = tools_menu() 
    import xylobium.dledit.Action;
    import dataman.actions.tools.*;
    
    ac_conf = Action("Configure Stabilization..", @configure_stabilize, false, true);
    ac_conf.menu_position = "Tools";
    ac_conf.accept_multiple_dlocs = true;
    ac_conf.can_queue = false;
    ac_conf.can_execute_without_dloc = false;
    
    ac_motion = Action("Stabilize", @stabilize, false, true);
    ac_motion.menu_position = "Tools";
    ac_motion.accept_multiple_dlocs = false;
    ac_motion.can_queue = true;
    ac_motion.can_execute_without_dloc = false;
    
    ac_convh5 = Action("Convert to H5", @convert_to_h5, false, true);
    ac_convh5.menu_position = "Tools";
    ac_convh5.accept_multiple_dlocs = false;
    ac_convh5.can_queue = true;
    ac_convh5.can_execute_without_dloc = false;
    
    ac_onpath = Action("Use on-path", @set_onpath, false, true);
    ac_onpath.menu_position = "Tools";
    ac_onpath.accept_multiple_dlocs = true;
    ac_onpath.can_queue = false;
    ac_onpath.can_execute_without_dloc = false;
    ac_onpath.menu_separator = true;
    
    ac_offpath = Action("Use off-path...", @set_offpath, false, true);
    ac_offpath.menu_position = "Tools";
    ac_offpath.accept_multiple_dlocs = true;
    ac_offpath.can_queue = false;
    ac_offpath.can_execute_without_dloc = false;
    ac_offpath.menu_separator = false;
    
    ac_copy_to_offpath = Action("Copy on-path to off-path", @copy_to_offpath, false, true);
    ac_copy_to_offpath.menu_position = "Tools";
    ac_copy_to_offpath.accept_multiple_dlocs = false;
    ac_copy_to_offpath.can_queue = true;
    ac_copy_to_offpath.can_execute_without_dloc = false;
    ac_copy_to_offpath.menu_separator = false;
    
    ac_copy_to_onpath = Action("Copy off-path to on-path", @copy_to_onpath, false, true);
    ac_copy_to_onpath.menu_position = "Tools";
    ac_copy_to_onpath.accept_multiple_dlocs = false;
    ac_copy_to_onpath.can_queue = true;
    ac_copy_to_onpath.can_execute_without_dloc = false;
    ac_copy_to_onpath.menu_separator = false;
    
    actions = [ac_conf ac_motion ac_convh5 ...
        ac_onpath ac_offpath ac_copy_to_offpath ac_copy_to_onpath];
    
    for action = actions; action.has_button = false; end
end


% constructs the tools menu:
function actions = roi_menu() 
    import xylobium.dledit.Action;
    import dataman.actions.roi.*;
      
    ac_refs = Action("Gener. ref. images", @make_reference_images, false, true, "o");
    ac_refs.menu_position = "RoIs";
    ac_refs.accept_multiple_dlocs = false;
    ac_refs.can_queue = true;
    ac_refs.can_execute_without_dloc = false;
    ac_refs.has_button = true;
    ac_refs.button_group = "Regions-of-interest";
    
    ac_mark = Action("Mark RoIs", @mark_rois, false, true, "m");
    ac_mark.menu_position = "RoIs";
    ac_mark.accept_multiple_dlocs = false;
    ac_mark.can_queue = false;
    ac_mark.can_execute_without_dloc = false;
    ac_mark.has_button = true;
    ac_mark.button_group = "Regions-of-interest";
    
    ac_proc = Action("Process RoIs", @process_rois, false, true);
    ac_proc.menu_position = "RoIs";
    ac_proc.accept_multiple_dlocs = false;
    ac_proc.can_queue = true;
    ac_proc.can_execute_without_dloc = false;
    ac_proc.has_button = true;
    ac_proc.button_group = "Regions-of-interest";
    
    ac_qa_signal = Action("Plot Signal", @qa_plot_signals, false, true);
    ac_qa_signal.menu_position = "RoIs";
    ac_qa_signal.menu_separator = true;
    ac_qa_signal.accept_multiple_dlocs = false;
    ac_qa_signal.can_queue = true;
    ac_qa_signal.can_execute_without_dloc = false;
    ac_qa_signal.has_button = false;
    
    ac_qa_roi = Action("Plot RoIs", @qa_plot_rois, false, true);
    ac_qa_roi.menu_position = "RoIs";
    ac_qa_roi.accept_multiple_dlocs = false;
    ac_qa_roi.can_queue = true;
    ac_qa_roi.can_execute_without_dloc = false;
    ac_qa_roi.has_button = false;
    
    ac_qa_ch_dr = Action("Plot channel and drift", @qa_plot_ch_drift, false, true);
    ac_qa_ch_dr.menu_position = "RoIs";
    ac_qa_ch_dr.accept_multiple_dlocs = false;
    ac_qa_ch_dr.can_queue = true;
    ac_qa_ch_dr.can_execute_without_dloc = false;
    ac_qa_ch_dr.has_button = false;
    
    ac_legacy_conv = Action("Convert legacy 'roi_array'", @convert_legacy, false, true);
    ac_legacy_conv.menu_position = "RoIs";
    ac_legacy_conv.menu_separator = true;
    ac_legacy_conv.accept_multiple_dlocs = false;
    ac_legacy_conv.can_queue = true;
    ac_legacy_conv.can_execute_without_dloc = false;
    ac_legacy_conv.has_button = false;
    
    actions = [ac_refs ac_mark ac_proc ac_qa_signal ac_qa_roi ac_qa_ch_dr ac_legacy_conv];
end


function actions = roa_menu()
    % Fixme Daniel :p
    
    import xylobium.dledit.Action;
    import dataman.actions.roa.*;
    
    not_impl = @(dloc, model, editor) warning("NOT IMPLEMENTED!");
    
    ac_auto_conf_preproc = Action("Auto Config", @(ts,~,~)begonia.processing.roa.config_auto(ts), true, false);
    ac_auto_conf_preproc.menu_separator = true;

    ac_auto_conf_preproc.menu_position = "RoAs";
    ac_auto_conf_preproc.accept_multiple_dlocs = true;    % USE THIS TO CONFIG MULTIPLE
    ac_auto_conf_preproc.can_queue = true;
    ac_auto_conf_preproc.can_execute_without_dloc = false;
    ac_auto_conf_preproc.has_button = true;
    ac_auto_conf_preproc.button_group = "Regions-of-Activity";
    
    ac_conf_preproc = Action("Manual Config", @begonia.processing.roa.gui_config_manual, false, true);
    ac_conf_preproc.menu_position = "RoAs";
    ac_conf_preproc.accept_multiple_dlocs = false;    % USE THIS TO CONFIG MULTIPLE
    ac_conf_preproc.can_queue = false;
    ac_conf_preproc.can_execute_without_dloc = false;
    ac_conf_preproc.has_button = true;
    ac_conf_preproc.button_group = "Regions-of-Activity";
    
    ac_preproc = Action("Pre-process", @(ts,~,editor)begonia.processing.roa.pre_process(ts,editor.get_misc_config('roa_recording_folder')), true, false);
    ac_preproc.menu_position = "RoAs";
    ac_preproc.accept_multiple_dlocs = false;
    ac_preproc.can_queue = true;
    ac_preproc.can_execute_without_dloc = false;
    ac_preproc.has_button = true;
    ac_preproc.button_group = "Regions-of-Activity";
    
    ac_thresh = Action("Threshold", @(ts,~,editor)begonia.processing.roa.gui_adjust_threshold(ts,editor.get_misc_config('roa_recording_folder'),editor), true, false);
    ac_thresh.menu_position = "RoAs";
    ac_thresh.accept_multiple_dlocs = false;
    ac_thresh.can_queue = false;
    ac_thresh.can_execute_without_dloc = false;
    ac_thresh.has_button = true;
    ac_thresh.button_group = "Regions-of-Activity";
    
    ac_proc = Action("Process", @(ts,~,editor) begonia.processing.roa.filter_roa(ts,editor.get_misc_config('roa_recording_folder')), true, false);
    ac_proc.menu_position = "RoAs";
    ac_proc.accept_multiple_dlocs = false;
    ac_proc.can_queue = true;
    ac_proc.can_execute_without_dloc = false;
    ac_proc.has_button = true;
    ac_proc.button_group = "Regions-of-Activity";
    
    ac_clean = Action("Clean intermediary files", @(ts,~,~) begonia.processing.roa.clean_temporary_files(ts), true, false);
    ac_clean.menu_position = "RoAs";
    ac_clean.accept_multiple_dlocs = false;
    ac_clean.can_queue = true;
    ac_clean.can_execute_without_dloc = false;
    ac_clean.has_button = true;
    ac_clean.button_group = "Regions-of-Activity";
    
    ac_toggle_tmpl = Action("Toggle template", @toggle_template, false, true);
    ac_toggle_tmpl.menu_position = "RoAs";
    ac_toggle_tmpl.accept_multiple_dlocs = true;    % USE THIS TO CONFIG MULTIPLE
    ac_toggle_tmpl.can_queue = false;
    ac_toggle_tmpl.can_execute_without_dloc = false;
    ac_toggle_tmpl.has_button = true;
    ac_toggle_tmpl.button_group = "Regions-of-Activity";
    ac_toggle_tmpl.reload_on_execute = true;
    
    ac_proc_tmpl = Action("Process by template", @process_by_template, false, true);
    ac_proc_tmpl.menu_position = "RoAs";
    ac_proc_tmpl.accept_multiple_dlocs = true;    % USE THIS TO CONFIG MULTIPLE
    ac_proc_tmpl.can_queue = true;
    ac_proc_tmpl.can_execute_without_dloc = false;
    ac_proc_tmpl.has_button = true;
    ac_proc_tmpl.button_group = "Regions-of-Activity";
    ac_proc_tmpl.reload_on_execute = true;
    
    
    % RPA
    ac_proc_rpa = Action("Process Activity", @(ts,~,~)begonia.processing.rpa.extract_signals(ts), true, false);
    ac_proc_rpa.menu_position = "RoAs";
    ac_proc_rpa.menu_separator = true;
    ac_proc_rpa.accept_multiple_dlocs = false;
    ac_proc_rpa.can_queue = true;
    ac_proc_rpa.can_execute_without_dloc = false;
    ac_proc_rpa.has_button = true;
    ac_proc_rpa.button_group = "Activity";
    
    ac_qa_rpa = Action("Plot RoI Activity", @(ts, ~, ~) begonia.processing.rpa.plot_qa_rpa(ts), false, true);
    ac_qa_rpa.menu_position = "RoAs";
    ac_qa_rpa.accept_multiple_dlocs = false;
    ac_qa_rpa.can_queue = true;
    ac_qa_rpa.can_execute_without_dloc = false;
    ac_qa_rpa.has_button = false;
    
    ac_qa_rpa_cmp = Action("Plot Compartment Activity", @(ts, ~, ~) begonia.processing.rpa.plot_qa_compartment(ts), false, true);
    ac_qa_rpa_cmp.menu_position = "RoAs";
    ac_qa_rpa_cmp.accept_multiple_dlocs = false;
    ac_qa_rpa_cmp.can_queue = true;
    ac_qa_rpa_cmp.can_execute_without_dloc = false;
    ac_qa_rpa_cmp.has_button = false;
    
    
    % PLOTS
    ac_qa_splatter = Action("Splatter Plot", @plot_splatter, false, true);
    ac_qa_splatter.menu_position = "RoAs";
    ac_qa_splatter.menu_separator = true;
    ac_qa_splatter.accept_multiple_dlocs = false;
    ac_qa_splatter.can_queue = true;
    ac_qa_splatter.can_execute_without_dloc = false;
    ac_qa_splatter.has_button = false;
    
    ac_qa_mask = Action("Visualize Mask", @visualize_mask, false, true);
    ac_qa_mask.menu_position = "RoAs";
    ac_qa_mask.accept_multiple_dlocs = false;
    ac_qa_mask.can_queue = false;
    ac_qa_mask.can_execute_without_dloc = false;
    ac_qa_mask.has_button = false;
    

    
    actions = [ac_toggle_tmpl ac_proc_tmpl ...
        ac_auto_conf_preproc ac_conf_preproc ac_preproc ac_thresh ac_proc ac_clean...
        ac_proc_rpa ac_qa_rpa ac_qa_rpa_cmp ...
        ac_qa_splatter ac_qa_mask ];
end