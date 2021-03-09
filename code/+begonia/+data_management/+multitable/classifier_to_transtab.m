function trans_f = classifier_to_trans(clfr, from, to)
    a = clfr.trace{:}(1:end-1);
    b = clfr.trace{:}(2:end);
    trans_f = find(a == from & b == to);
end

