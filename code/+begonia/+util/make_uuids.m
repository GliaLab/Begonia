function uuids = make_uuids(n)
    for i = 1:n
        uuids(i,:) = begonia.util.make_uuid();
    end
end

