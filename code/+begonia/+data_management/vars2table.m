function tbl = vars2table(dlocs,vars)
if ischar(vars)
    vars = {vars};
end
assert(iscellstr(vars));

uuids = categorical({dlocs.uuid});

tbl = begonia.data_management.var2table(dlocs,vars{1});
for i = 2:length(vars)
    tbl_tmp = begonia.data_management.var2table(dlocs,vars{i});
    tbl = innerjoin(tbl,tbl_tmp);
end

[~,I] = ismember(uuids,tbl.uuid);

tbl = tbl(I,:);

end

