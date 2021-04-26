function convert_prarie_to_h5(folder,h5_folder,include_var_data,include_uuid)
if nargin < 3
    include_var_data = false;
end
if nargin < 4
    include_uuid = false;
end

ts = begonia.scantype.find_scans(folder);

for i = 1:length(ts)
    if ~isa(ts(i),'begonia.scantype.prairie.TSeriesPrairie')
        continue;
    end
    
    % Find misc files to copy. Better safe than sorry.
    files = dir(fullfile(ts(i).path,"**"));
    files = files(~[files.isdir]);
    
    % Filter out unwanted files.
    files = files(~contains({files.name},".ome.tif"));
    if ~include_uuid
        files = files(~contains({files.name},"uuid.begonia"));
    end
    files = files(~contains({files.name},".DS_Store"));
    var_files = files(contains({files.name},"var."));
    files = files(~contains({files.name},"var."));
    
    new_ts_path = strrep(ts(i).path,folder,h5_folder);
    new_metadata_folder = new_ts_path + ".metadata";
    
    for j = 1:length(files)
        file_path = fullfile(files(j).folder,files(j).name);
        new_file_path = strrep(file_path,ts(i).path,new_metadata_folder);
        begonia.path.make_dirs(new_file_path);
        copyfile(file_path,new_file_path);
    end
    
    if include_var_data
        for j = 1:length(var_files)
            file_path = fullfile(var_files(j).folder,var_files(j).name);
            new_file_path = strrep(file_path,ts(i).path,new_metadata_folder);
            begonia.path.make_dirs(new_file_path);
            copyfile(file_path,new_file_path);
        end
    end
    
    begonia.scantype.h5.tseries_to_h5(ts(i),new_ts_path);
end

end

