clearvars;

%ts = begonia.scantype.h5.TSeriesH5('/Users/knut/Documents/Local data/TSeries-05022018-1058-067_aligned');
%ts = begonia.scantype.h5.TSeriesH5('F:\Local data\TSeries-08272018-0713-008_aligned');
ts = begonia.scantype.h5_old.TSeriesH5Old('C:\Users\knuta\Documents\Local data\TSeries-02202018-0826-019_aligned');

% ts_src = begonia.scantype.h5_old.TSeriesH5Old('C:\Users\knuta\Documents\Local data\TSeries-02202018-0826-019_aligned');
% roa_mask = ts_src.load_var("roa_mask_ch01");
% ts = begonia.scantype.matlab.TSeriesMatrixAdapter(roa_mask);

% create app
app = roiman.App(); % creates an instance of the roimanager

% open a tseries + view for roi editing:
vm = app.open(ts); % opens the data by assigning a view manager to it
roiman.initializers.init_roi_editing(vm);


ch2 = roiman.modules.Channel("Channel view", 1);
status = roiman.modules.StatusOverlay("Status overlay");
rois = roiman.modules.Rois("RoIs", 1);
roipaint = roiman.modules.RoIPaintOverlay("RoI Paint Overlay");

vm.new_view(ts.name, [ch2, status rois roipaint]);

 % sets up initial roi editing values
vm.add_mode(roiman.modes.RoIPaint()); % rp - roi painting
vm.add_mode(roiman.modes.RoISelect()); % rs - selection and grouping 

% view 1 : astrocyte channel:

vm2 = app.open(ts); % opens the data by assigning a view manager to it
ch2 = roiman.modules.Channel("Channel view", 1);
status = roiman.modules.StatusOverlay("Status overlay");
vm2.new_view(ts.name, [ch2, status]);

% add tools:
app.add_tool("manager", @roiman.tools.Manager);
app.add_tool("channel", @roiman.tools.Channel);
app.add_tool("guide", @roiman.tools.Guide);
app.add_tool("rois", @roiman.tools.RoIs);
app.run();


% debug flags
%vm.data.write("debug_mouse_coords", true);
%vm.data.write("debug_report_spline_redraws", true);

% run with debug if there are errors hidden by timers' poor exception
% reporting in Matlab (crazy bad, to be honest).
%vm.run_debug();

