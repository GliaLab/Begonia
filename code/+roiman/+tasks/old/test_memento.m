run_test();

function run_test()
    mem = roiman.Memento(10);

    % create a editable string (strings are share-by-copy, so we need a handle
    % based thing to test the memento):
    text = roiman.tests.Text();
    text.content = "Hello memento";
    
    assert(text.content == "Hello memento");

    function change(txt) 
        text.content = txt;
    end

    % perform two edits:
    
    % edit 1 - set to "Hello World"
    % note: if we bound the undo straight to to text.content, it would not 
    % work as this would change at runtime. Text is ahn
    old = text.content; 
    mem.do(@() change("Hello world"), "Set to HW", @() change(old));
    
    
    % edit 2 - set to "How cliché"
    old = text.content;
    mem.do(@() change("How cliché"), "Set to HC", @() change(old));
    
    % we should now have possibility to unto twice:
    assert(text.content == "How cliché");
    assert(length(mem.history) == 2)

    % roll back, then forwards:
    mem.undo(); assert(text.content == "Hello world")
    mem.undo(); assert(text.content == "Hello memento")
    
end