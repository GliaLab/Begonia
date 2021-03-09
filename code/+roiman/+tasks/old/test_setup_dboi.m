clearvars;

ts = begonia.scantype.find_scans('/Users/lastis/Attic/Test TSeries');
ts = ts(1);

% create roi manager
vm = roiman.ViewManager(ts);


% install modes for roi editing - modes must be installed before views are
% created to ensure they get a chance to add required data:
roiman.initializers.init_roi_editing(vm); % sets up initial roi editing values
vm.add_mode(roiman.modes.RoIPaint()); % rp - roi painting
vm.add_mode(roiman.modes.RoISelect()); % rs - selection and grouping 
vm.add_mode(roiman.modes.RoIFill()); % rf - fill by pixel treshold

% view 1 : astrocyte channel:
ch2 = roiman.modules.Channel("Astrocytes", 1);
rois = roiman.modules.Rois("RoIs (channel 2)", 1);
roipaint = roiman.modules.RoIPaintOverlay("RoI Paint Overlay");
status = roiman.modules.StatusOverlay("Status CH2");

vm.new_view("new", "Channel 1 (Astrocytes)", [ch2, rois roipaint status]);

% view 2 : neuron chanel
%ch3 = roiman.modules.Channel("Neurons (Ch3)", 2);
%status_ch3 = roiman.modules.StatusOverlay("Status CH3");

%vm.new_view("new", "Channel 2", [ch3 roipaint_neu status_ch3]);

% add tools:
vm.open_tool("manager", @roiman.tools.Manager);
% vm.open_tool("channel", @roiman.tools.Channel);
% vm.open_tool("guide", @roiman.tools.Guide);
vm.open_tool("rois", @roiman.tools.RoIs);

vm.run();

