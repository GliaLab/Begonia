function rememeber_session(editor)
    import dataman.support.*;

    % save this to prefs for easy re-open:
    sessions = read_prefs("sessions", string.empty);
    sessions = [editor.session_file ; sessions];
    sessions = unique(sessions, "stable");
    if length(sessions) > 5
        sessions = sessions(1:5);
    end
    write_prefs("sessions", sessions);
end

