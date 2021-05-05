function save_average_as_tiff(folder,folder_out)

ts = begonia.scantype.find_scans(folder);

for i = 1:length(ts)
    img_merged = zeros([ts(i).img_dim,3]);
    for ch = 1:ts(i).channels
        [directory,file,ext] = fileparts(ts(i).path);
        path = fullfile(directory,file);
        filename = strrep(path,folder,folder_out) + " Ch" + ch + ".tif";
        
        img = ts(i).get_avg_img(ch,1,false);
        img = img / max(img(:));
        begonia.path.make_dirs(filename);
        if ch <= 3
            % Save image to make a merged image later.
            img_merged(:,:,ch) = img;
            
            % Change the color of the image.
            tmp = img;
            img = zeros([ts(i).img_dim,3]);
            img(:,:,ch) = tmp;
        end
        imwrite(img,filename);
    end
    
    if ts(i).channels == 2 || ts(i).channels == 3
        [directory,file,ext] = fileparts(ts(i).path);
        path = fullfile(directory,file);
        filename = strrep(path,folder,folder_out) + " Merged" + ".tif";
        imwrite(img_merged,filename);
    end
    
end

end

