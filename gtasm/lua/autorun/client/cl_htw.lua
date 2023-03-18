gTASMHTW = {}
gTASMHTW.lastP = "start"

concommand.Add( "gt_htw", function() 
    gTASMHTW:Open()
end)

local function OpenHTWFile(name)
    local fhtm

    if file.Exists( "gtasm_data/"..name..".txt", "DATA" ) then
        fhtm = file.Read( "gtasm_data/"..name..".txt", "DATA" )
    else
        fhtm = file.Read( "gtasm_data/not_found.txt", "DATA" )
    end

    return fhtm
end

function gTASMHTW:Open()
    local function formatP(page)
        local main_p = OpenHTWFile("main")

        local thtml = string.Replace( main_p, "!list!", OpenHTWFile("list"))
        local thtml2 = string.Replace( thtml, "!page!",  OpenHTWFile(page) )

        return thtml2
    end
    
    local frame = vgui.Create("DFrame")
    frame:SetSize(1000, 700)
    frame:SetTitle("Helper")
    frame:SetVisible(true)
    frame:SetDraggable(true)
    frame:MakePopup()
    frame:Center()
    
    local panel = vgui.Create("DPanel",frame)
    panel:Dock(FILL)

    local html = vgui.Create("DHTML", frame)
    html:SetAllowLua(true)
    html:Dock(FILL)
    
    data = formatP(gTASMHTW.lastP)
    html:SetHTML(data)

    html:AddFunction( "dhtw", "changePage", function( str )
        --print(str)
        data = formatP(str)
        html:SetHTML(data)
    end)

end