function str_out = escape_special_chars(str,special_chars)
%ESCAPE_SPECIAL_CHARS adds escape characters to some common signs. 
%
%   str_out = escape_special_chars(str)
%   str_out = escape_special_chars(str,special_chars)
%
%   REQUIRED
%   str             - (cell of char or char)
%                       Input string
%
%   PARAMETERS
%   special_chars   - (char)
%                       List of special characters to escape.
%                       default : '[]{}() '
%
%   RETURNED
%   str_out         - (cell of char or char)
%                       Output string with replaced chars. 
if nargin < 2
    special_chars = '[]{}() ';
end

for i = 1:length(special_chars)
    str = strrep(str,special_chars(i),['\',special_chars(i)]);
end
str_out = str;
