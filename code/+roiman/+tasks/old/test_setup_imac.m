clearvars;

ts = begonia.scantype.h5.TSeriesH5('/Volumes/Disk 2/E400 ArcSwe/Data - complete set/images/batch 3/E400b3 - day 4 mic/TSeries-08272018-0713-010_aligned');

ch2 = roiman.modules.Channel("Astrocyte (Ch2)", 1);
ch3 = roiman.modules.Channel("Neurons (Ch3)", 2);
rois = roiman.modules.Rois("RoIs (channel 2)", 1);
%roas = roiman.modules.Roas("Roas");


vm = roiman.ViewManager(ts);
vm.new_view("Channel 1 + rois", [ch2, rois]);
vm.new_view("Channel 2", ch3);
%vm.new_view("Channel 1 + roas", [ch2, roas]);

vm.open_tool("manager", @roiman.tools.Manager);
% vm.open_tool("roieditor", @roiman.tools.RoiEditor);
% vm.open_tool("roilist", @roiman.tools.RoIList);
vm.open_tool("channel", @roiman.tools.Channel);

% debug view changes: