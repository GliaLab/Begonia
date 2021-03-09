classdef Stash 
    %STASH Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        path
    end
    
    methods
        % Object to store objects as individual mat files in a folder
        % structure:
        function obj = Stash(path)
            import begonia.util.logging.*;
            
            obj.path = string(path);
            if ~exist(path, 'dir')
                mkdir(obj.path);
                vlog(2, "Stash: Established folder " + path);
            end
            
        end
        
        % getn an item from the stash using the url returned upon storage:
        function item = get(obj, url, default)
            
            
            url = string(url);
            mfile = obj.decompose_and_check_url(url);

            try
                loaded = load(mfile);
                item = loaded.item;
            catch 
                if nargin > 2 
                    item = default;
                else
                    error("Could not unstash url " + url + ...
                        " - provide a default parameter of stop crashing here (⚆ _ ⚆)");
                    
                end
                
            end
        end
        
        % retrieve multiple URLs:
        function items = gets(obj, urls)
            if ~isa(urls, 'string'); error('Urls must be a list of *strings*'); end
            
            for i = 1:length(urls)
                items(i,:) = obj.get(urls(i)); %#ok<NASGU>
            end
        end
        
        % put an item in the stash
        function url = put(obj, namespace, ident, item)
            % ensure string format:
            namespace = string(namespace); 
            ident = string(ident);
            
            % ensure namespace directory exists:
            obj.validate_namespace(namespace)
            
            fname = obj.mat_name(namespace, ident);
            save(fname, 'item', '-v7.3');
            
            url = "stash://" + namespace + "/" + ident;
        end
        
        
        function urls = puts(obj, namespace, idents, items)
            if ~isa(idents, 'string'); error('Idents must be a list of *strings*'); end
            if length(idents) ~= length(items);  error('Idents and items must have the same length'); end
            
            urls = strings(length(items), 1);
            for i = 1:length(items)
                item = items(i);
                ident = idents(i);
                urls(i) = obj.put(namespace, ident, item);
            end
        end
        
        
        function tab = unstash_table(obj, tsrc)
            tab = table();
            for varcell = tsrc.Properties.VariableNames
                var = varcell{:};
                vals = tsrc.(var);
                if isa(vals(1), 'string') && startsWith(vals(1), "stash://")
                    urls = tsrc.(var);
                    tab.(var) = obj.gets(urls);
                else
                    tab.(var) = vals;
                end
            end
        end
        
        
        function tab = stash_table(obj, namespace, tsrc, columns)
            tab = table();
            for varcell = tsrc.Properties.VariableNames
                var = varcell{:};
                if ~contains(columns, var)
                    tab.(var) = tsrc.(var);
                else
                    vals = tsrc.(var);
                    idents = begonia.util.make_uuids(length(vals));
                    urls = obj.puts(namespace, string(idents), vals);
                    tab.(var) = urls;
                end
            end
        end
        
        % clear the namespace:
        function clear_namespace(obj, namespace)
            nsdir = fullfile(obj.path, namespace);
            if exist(nsdir, 'dir')
                rmdir(nsdir);
            end
        end
        
    end
    
    methods (Access = private)
        
        % get mat name
        function [fname, nsdir] = mat_name(obj, namespace, ident)
            nsdir = fullfile(obj.path, namespace);
            fname = fullfile(nsdir, ident + ".mat");
        end
        
        % establish namespace if it does not exist:
        function validate_namespace(obj, namespace)
            import begonia.util.logging.*;
            [~, nsdir] = obj.mat_name(namespace, "");
            if ~exist(nsdir)
                vlog(2, "Namesapce " + namespace + " does not exist - making dir");
                mkdir(nsdir);
            end
        end
        
        function [mfile, ident, ns, is_present] = decompose_and_check_url(obj, url)
            % we expect: stash://namespace/identity
            parts = split(url, "/");
            if length(parts) ~= 4 && parts(1) ~= "stash:"
                error("Faulty URL format. Must be 'stash://namespace/identity'");
            end
            
            ns = parts(3);
            ident = parts(4);
            
            mfile = obj.mat_name(ns, ident);
            if nargout > 3
                is_present = exist(mfile, 'file') ~= 0;
            end
        end
    end
end

