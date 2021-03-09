function toTable( ~, model, ~)
    [fname,fpath] = uiputfile('Table.xlsx','Save file name (extention sets type)');
    if fname == 0
       return 
    end
    
    tbl = model.getFullTable();

    fullpath = fullfile(fpath, fname);
    writetable(tbl, fullpath);
end

