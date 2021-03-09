function backwrite(level,varargin)
if nargin == 1
    error('Not enough input arguments.')
end

if nargin > 1
    assert(isnumeric(level),'Log level must be a numeric value');
end

global BEGONIA_VERBOSE;
global begonia_backwrite_previous_msg
global begonia_previous_msg


if nargin == 0
    begonia_backwrite_previous_msg = '';
    return;
end

msg = sprintf(varargin{:});
% Hack to be able to write percent. This is needed because the msg is
% created using sprintf and then written using fprintf. 
num_extra_symbols = sum(msg == '%') + sum(msg == '\');
msg = strrep(msg,'%','%%');
msg = strrep(msg,'\','\\');

highjack_msg = 'begonia.util.logging.backwrite highjacked the lastwarn message.';
if ~isequal(lastwarn,highjack_msg)
    begonia_backwrite_previous_msg = '';
    
    lastwarn(highjack_msg);
end

if BEGONIA_VERBOSE >= level
    now = datetime('now');
    now.Format = 'HH:mm:ss';
    now = char(now);
    msg = ['[',now,'] : ',msg];

    if isequal(begonia_backwrite_previous_msg,begonia_previous_msg)
        prev = repmat('\b',1,length(begonia_backwrite_previous_msg) + 1 - num_extra_symbols);
    else
        prev = '';
    end
    
    fprintf([prev,msg,'\n']);
    
    begonia_backwrite_previous_msg = msg;
    begonia_previous_msg = msg;
end

end

