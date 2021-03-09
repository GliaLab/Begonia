function scans = find_scans(path,print)
if nargin < 2
    print = true;
end

if print
    begonia.logging.log(1,'Finding scans.');
end

classes = {...
    @begonia.scantype.h5.TSeriesH5, ...
    @begonia.scantype.h5_old.TSeriesH5Old, ...
    @begonia.scantype.tiff.TSeriesTIFF, ...
    @begonia.scantype.prairie.TSeriesPrairie};
avoid = {'LineScan-','TSeries-','SingleImage-','ZSeries-'};
ignore = {'.BIN','.Trashes','.DS_Store','metadata','uuid.begonia'};

scans = begonia.scantype.find_objects(path,classes,avoid,ignore,print);

end