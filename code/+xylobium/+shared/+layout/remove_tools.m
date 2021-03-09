function remove_tools(fig)
    try
    %% Removes some buttons from tool bar
    dck = findall(fig, 'Tooltipstring', 'Show Plot Tools and Dock Figure');
    dck.Visible = 'off';
    hdpl = findall(fig, 'Tooltipstring', 'Hide Plot Tools');
    hdpl.Visible = 'off';
    insl = findall(fig, 'Tooltipstring', 'Insert Legend');
    insl.Visible = 'off';
    insc = findall(fig, 'Tooltipstring', 'Insert Colorbar');
    insc.Visible = 'off';
    lnkpl = findall(fig, 'Tooltipstring', 'Link Plot');
    lnkpl.Visible = 'off';
    brsh = findall(fig, 'Tooltipstring', 'Brush/Select Data');
    brsh.Visible = 'off';
    dta = findall(fig, 'Tooltipstring', 'Data Cursor');
    dta.Visible = 'off';
    rt = findall(fig, 'Tooltipstring', 'Rotate 3D');
    rt.Visible = 'off';
    ed = findall(fig, 'Tooltipstring', 'Edit Plot');
    ed.Visible = 'off';
    op = findall(fig, 'Tooltipstring', 'Open File');
    op.Visible = 'off';
    nf = findall(fig, 'Tooltipstring', 'New Figure');
    nf.Visible = 'off';
    pf = findall(fig, 'Tooltipstring', 'Print Figure');
    pf.Visible = 'off';
    sf = findall(fig, 'Tooltipstring', 'Save Figure');
    sf.Visible = 'off';
    hFileMenu = findall(fig, 'tag', 'figMenuFile');
    hFileMenu.Visible = 'off';
    hFileMenu = findall(fig, 'tag', 'figMenuEdit');
    hFileMenu.Visible = 'off';
    hFileMenu = findall(fig, 'tag', 'figMenuView');
    hFileMenu.Visible = 'off';
    hFileMenu = findall(fig, 'tag', 'figMenuInsert');
    hFileMenu.Visible = 'off';
    hFileMenu = findall(fig, 'tag', 'figMenuTools');
    hFileMenu.Visible = 'off';
    hFileMenu = findall(fig, 'tag', 'figMenuDesktop');
    hFileMenu.Visible = 'off';
    hFileMenu = findall(fig, 'tag', 'figMenuWindow');
    hFileMenu.Visible = 'off';
    hFileMenu = findall(fig, 'tag', 'figMenuHelp');
    hFileMenu.Visible = 'off';
    catch err
        warning('Could not clean window toolbar - bug?');
    end

end

