function id = make_snowflake_id(prefix, seed)
    if nargin < 1
        prefix = 'Snowflake';
    end
    
    if isstring(prefix)
        prefix = char(prefix);
    end
    
    % save current random number generator, then reseed:
    % (tried with RandomStream, but couldnt get it to work)
    if nargin > 1
        old_gen = rng();
        if isa(seed, 'datetime')
            seed_nr = seconds(seed - datetime(1983, 08,04,0,0,0));
            rng(seed_nr);
            warning('Snowflake IDs based on datetime could be unreliable');
        else
            rng(seed);  % messes with whole matlab state??
        end
    end
    
    % generator snowflake ID:
    id = [prefix ' ' ...
                char(randi([65 90],1,1)) ...
                num2str(floor(rand(1,1) * 99)) ...
                '-' num2str(floor(rand(1,1) * 9999))];
            
    % restore old generator:
    if nargin > 1
        rng(old_gen);
    end
end

