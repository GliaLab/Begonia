% gives s string corresponding to the keyboard event that can be used to
% trigger shortcuts:
function code = keyboard_event_to_str(ev)
    code = '';
    mods = sort(ev.Modifier);
    desc_mods = mods(end:-1:1);

    for mod = desc_mods
         code = [mod{:} '-' code];
    end
    
    code = [code ev.Key];
end

