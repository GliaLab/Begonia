function eqtab = equisize_left(traces, eq_strat, dt)
    % make equaly sampled:
    eqtab = begonia.data_management.multitable.resample(traces, dt);

    if eq_strat == "trim"
        end_f = min(arrayfun(@(tr) length(tr{:}), eqtab.trace));
    elseif eq_strat == "padd"
        end_f = max(arrayfun(@(tr) length(tr{:}), eqtab.trace));
        error("Not implmeented");
    end
    
    eqtab.trace = cellfun(@(t) t(1:end_f), eqtab.trace, "UniformOutput", false);
end

