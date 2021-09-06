function log(level, varargin)
if nargin == 1
    error('Not enough input arguments.')
end

if nargin > 1
    assert(isnumeric(level),'Log level must be a numeric value');
end

global BEGONIA_VERBOSE;
global begonia_previous_msg;

msg = sprintf(varargin{:});

if BEGONIA_VERBOSE >= level
    now = datetime('now');
%     now.Format = 'HH:mm:ss';
    now = char(now);
    msg = sprintf('[%s] : %s',now,msg);
    disp(msg);
    begonia_previous_msg = msg;
end

end