function validatestring(x,validStrings)

if ~any(strcmp(x,validStrings))
    str = sprintf('Expected input to match one of these values:');
    str = strcat(str,'\n\n');
    for i = 1:length(validStrings)
        str_tmp = sprintf(' ''%s'',',validStrings{i});
        str = strcat(str,str_tmp);
    end
    str(end) = [];
    str = strcat(str,'\n\n');
    str_tmp = sprintf('The input, ''%s'', did not match any of the valid values.',x);
    str = strcat(str,str_tmp);
    
    error('begonia:validators:invalid_arguments', str);
end

end

