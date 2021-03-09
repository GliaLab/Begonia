clearvars; 

vd = roiman.prototyping.VersionedData();

%% Basic operations
disp("Basic operations + expected error")

d1 = vd.read("first", "hello");
d2 = vd.read("second", "world");

% this should fail:
try
    [d1,v1] = vd.read("first");
    [d2,v2] = vd.read("second");
catch err
    disp(err);
end

vd.write("demo_1", "hello");
vd.write("demo_2", "world (:");

join([vd.read("demo_1"), vd.read("demo_2")]);


v1 = vd.write("demo_1", "hello again");
v2 = vd.write("demo_2", "dear world");
join([vd.read("demo_1"), vd.read("demo_2")]);

%% test of execution speed
%{
Results:
containers.Map 9 data-cells 10k rws: 
    Elapsed time is 0.616071 seconds.
    Elapsed time is 0.449590 seconds.

struct.(key) + data-cells 10k rws:
    Elapsed time is 0.175674 seconds.
    Elapsed time is 0.079724 seconds.
    Dramatically better than map!

double struct prop 10k rws:
    Elapsed time is 0.148602 seconds.
    Elapsed time is 0.073788 seconds.
    
double stuct no index 10k rws:
    Elapsed time is 0.111747 seconds.
    Elapsed time is 0.073417 seconds.

%}
n = 100;
disp(n + "x read/writes");

for i = 1:n
    keys(i) = "F" + string(round(rand() * 10000000000));
end

% rapid write of strings:
tic;
for key = keys
    vd.write(key, key);
end
toc;

% rapid read of written data:
tic;
for key = keys
    data = vd.read(key);
end
toc;


%% performa change flag operation:
disp("Change flags")
a = struct(); b = struct();
a.test = "I am A"; b.test = "I am B";
vd.write("A", a);
vd.write("B", b);

tic
vd.assign_changeflag("A", "flag_a");
vd.assign_changeflag("B", "flag_a");
assert(vd.check("flag_a"));
assert(~vd.check("flag_a"));
toc

vd.write("A", "new thing!");
assert(vd.check("flag_a"));
assert(~vd.check("flag_a"));






















