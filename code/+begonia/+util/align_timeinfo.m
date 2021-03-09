function [I_1,I_2,offsets] = align_timeinfo(varargin)
% align_timeinfo finds TimeInfo objects that starts within a time window.
%
%   [I_1,I_2,offsets] = align_timeinfo(array_1_times,array_2_times)
%   [I_1,I_2,offsets] = align_timeinfo(...,NAME,VALUE)
%
%   REQUIRED
%   array_1_times       - (datetime) array.
%   array_2_times       - (datetime) array.
%
%   PARAMETERS
%   time_window         - (duration) 
%                           Default : seconds(30). The window around
%                       array_1 start_time which will be associated with
%                       array_2. 
%
%   lag                 - (duration)
%                           Default : seconds(0). Lag is subtracted from 
%                       the start time of each element in array_2. 
%
%   set_time_correction - (logical)
%                           Default: false. Sets the time correction of
%                       elements in array_2 so the start time matches the
%                       start time of associated TimeInfo in array_1. Will
%                       first reset all time_correction of all elements in
%                       array_1 and array_2.
%
%   RETURNED
p = inputParser;
p.addRequired('array_1_times',...
    @(x) validateattributes(x,{'datetime'},{}));
p.addRequired('array_2_times',...
    @(x) validateattributes(x,{'datetime'},{}));
p.addParameter('time_window',seconds(30),...
    @(x) validateattributes(x,{'duration'},{'nonempty'}));
p.addParameter('lag',seconds(0),...
    @(x) validateattributes(x,{'duration'},{'nonempty'}));
p.parse(varargin{:});

array_1_times = p.Results.array_1_times;
array_2_times = p.Results.array_2_times;
time_window = p.Results.time_window;
lag = p.Results.lag;

%% Create time arrays
array_2_times = array_2_times - lag;

%% Associate time info
I_1 = [];
I_2 = [];

begonia.logging.log(1,'Associating time info');
for i = 1:length(array_1_times)
    % Get the index of the closest element in array_2
    [delay,j] = min(abs(array_2_times - array_1_times(i)));
    
    if delay > time_window
        continue;
    end
    
    % Add the indices to the list.
    I_1 = cat(2,I_1,i);
    I_2 = cat(2,I_2,j);
end

offsets = array_2_times(I_2) - array_1_times(I_1) + lag;

%% Print

str = sprintf('Number of associated elements    : %d',length(offsets));
begonia.logging.log(1,str);

str = sprintf('Mean time offset                 : %s',char(mean(offsets-lag)));
begonia.logging.log(1,str);

str = sprintf('Std time offset                  : %s',char(std(offsets-lag)));
begonia.logging.log(1,str);

str = sprintf('Min time offset                  : %s',char(min(offsets-lag)));
begonia.logging.log(1,str);

str = sprintf('Max time offset                  : %s',char(max(offsets-lag)));
begonia.logging.log(1,str);

end

