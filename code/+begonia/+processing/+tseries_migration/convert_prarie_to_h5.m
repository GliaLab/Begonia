function convert_prarie_to_h5(folder,h5_folder,misc_folder)

ts = begonia.scantype.find_scans(folder);

for i = 1:length(ts)
    if ~isa(ts(i),'begonia.scantype.prairie.TSeriesPrairie')
        continue;
    end
    
    xml = begonia.path.find_files(ts(i).path,'.xml',false);
    for j = 1:length(xml)
        xml_new = strrep(xml{j},folder,misc_folder);
        begonia.path.make_dirs(xml_new);
        copyfile(xml{j},xml_new);
    end
    
    csv = begonia.path.find_files(ts(i).path,'.csv',false);
    for j = 1:length(csv)
        csv_new = strrep(csv{j},folder,misc_folder);
        begonia.path.make_dirs(csv_new);
        copyfile(csv{j},csv_new);
    end
    
    path_new = strrep(ts(i).path,folder,h5_folder);
    begonia.scantype.h5.tseries_to_h5(ts(i),path_new);
end

end

