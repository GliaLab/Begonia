function set_global_level(level)
    global BEGONIA_VERBOSE;
    %SET_GLOBAL_LEVEL Summary of this function goes here
    %   Detailed explanation goes here
    BEGONIA_VERBOSE = level;
    disp(['BEGONIA_VERBOSE log level set to ' num2str(level)]);
end

