dcarr = roiman.VersionedData();

%% empty objects should not crash:
[val, version] = dcarr.read("demo");
assert(isempty(val), "data carriers should return empty values");


%% assert that putting data in gets the same things out:
n = rand();
s = struct();
s.value = 42;

dcarr.write("number", n);
dcarr.write("struct", s);

assert(dcarr.read("number") == n);
assert(dcarr.read("struct").value == s.value);

%% check performance of this mechansm by setting 10000 random strings:
n = 1000;
disp("Testing time with " + n + " versioned values");
for i = 1:n
    key(i) = "key_" + i;
    value(i) = "value " + rand();
end

disp("Write")
tic
for i = 1:n
    dcarr.write(key(i), value(i));
end
toc

disp("Read")
tic
for i = 1:n
    val = dcarr.read(key(i));
end
toc
