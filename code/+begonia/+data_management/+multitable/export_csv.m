function expdir = export_csv(traces, outdir, traces_pr_file, prefix)
    if nargin < 4
        prefix = "Export " + datestr(now, "yymmdd-HHMMSS");
    end
    
    if nargin < 3
        traces_pr_file = 100;
    end
    
    if nargin < 2 
        outdir = pwd();
    end
    
    if ~exist(outdir, "dir")
        error("export directory does not exist: " + outdir)
    end
    
    n = height(traces);
    lengths = cellfun(@length, traces.trace);
    
    % prepare to recieve index information in trace table:
    traces.trace_colname = repmat("", n, 1);
    traces.trace_file = repmat("", n, 1);
    traces.trace_type = repmat("", n, 1);
    traces.trace_length = lengths;
    
    col_base = nan(max(lengths), 1);
    
    % make export directory:
    expdir = fullfile(outdir, prefix);
    mkdir(expdir);
    disp("Exporting to: " + expdir);
    
    % walk the traces, and write traces to file:
    chunk = 1;
    chunk_traces = 1;
    trace_tab = table();
    
    for r = 1:n
        row = traces(r,:);
        
        trace_file = "Traces " + chunk + ".csv";
        trace_path = fullfile(expdir, trace_file);
        colname = matlab.lang.makeValidName("trace_" + r + "_" + row.category);
        
        traces.trace_colname(r) = colname;
        traces.trace_file(r) = trace_file;
        traces.trace_type(r) = class(row.trace{:});
    
        trace = row.trace{:};
        
        trace_col = col_base;
        trace_col(1:length(trace)) = trace;
        trace_tab.(colname) = trace_col;
        
        chunk_traces = chunk_traces + 1;
        if chunk_traces > traces_pr_file || r == n
            chunk = chunk + 1;
            chunk_traces = 1;
            writetable(trace_tab, trace_path);
            disp("Wrote file: " + trace_file);
            trace_tab = table();
        end
    end
    
    % export index of the export:
    traces.trace = [];
    index_path = fullfile(expdir, "Index.csv");
    writetable(traces, index_path);
    disp("Done (ᵔᴥᵔ)");
end

