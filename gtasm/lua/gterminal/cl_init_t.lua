include("sh_init_t.lua");
include("cl_redactor.lua")

if file.IsDir( "gtasm", "DATA" ) == false then
    file.CreateDir("gtasm")
	MsgC(Color(0, 255, 0), "Created gtasm directory\n");
end

helperList = false

function dsplit(s, delimiter)
	result = {};
	for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        if (match==" ") or (match=="") or (match==nil) then
        else 
		table.insert(result, match);
        end 
	end
	return result;
end


local function SendKeyToServer(key)
	local ply = LocalPlayer()
	net.Start("gT_ActiveKeyType")
	net.WriteEntity(ply.gT_Entity)
	net.WriteInt(key,9)
	net.SendToServer()
end

local function EndKeyType()
	local ply = LocalPlayer()
	net.Start("gT_EndKeyType")
	net.WriteEntity(ply.gT_Entity)
	net.SendToServer()
end

surface.CreateFont("gT_ConsoleFont", {
	size = 28,
	weight = 800,
	antialias = true,
	font = "Lucida Console"
} );

local table = table;
local gTerminal = gTerminal;
local net = net;

net.Receive("gT_AddLine", function(length)
	local index = net.ReadUInt(16);
	local text = net.ReadString();
	local colorType = net.ReadUInt(8);
	local position = net.ReadInt(16);

	if ( !gTerminal[index] ) then
		gTerminal[index] = {};
	end;

	if (!position or position == -1) then
		table.insert( gTerminal[index], {text = text, color = colorType} );
	else
		gTerminal[index][position] = {text = text, color = colorType};
	end;

	if (#gTerminal[index] > 24) then
		table.remove(gTerminal[index], 1);
	end;
	
end);

net.Receive("gT_ActiveConsole", function()
	local index = net.ReadUInt(16);
	local entity = Entity(index);
	local client = LocalPlayer();

	if ( IsValid(entity) ) then
		client.gT_Entity = entity;
		client.gT_TextEntry = vgui.Create("DTextEntry");
		client.gT_TextEntry:SetSize(0, 0);
		client.gT_TextEntry:SetPos(0, 0);
		client.gT_TextEntry:MakePopup();

		client.gT_TextEntry.OnTextChanged = function(textEntry)
			local offset = 0;
			local text = textEntry:GetValue();

			if (string.len(text) > 50) then
				offset = textEntry:GetCaretPos() - 47;
			end;

			entity.consoleText = string.sub(text, offset);
		end;

		client.gT_TextEntry.OnEnter = function(textEntry)
			net.Start("gT_EndConsole");
				net.WriteUInt(index, 16);
				net.WriteString( tostring( textEntry:GetValue() ) );
			net.SendToServer()

			textEntry:SetText("");
			textEntry:SetCaretPos(0);

			entity.consoleText = "";
		end;
	end;
end);

net.Receive("gT_EndTyping", function(length)
	local client = LocalPlayer();

	if ( !IsValid(client.gT_TextEntry) ) then
		return;
	end;

	client.gT_TextEntry:Remove();

	if ( IsValid(client.gT_Entity) ) then
		client.gT_Entity.consoleText = "";
	end;
end);


MsgC(Color(0, 255, 0), "Loading gTerminal!\n");

hook.Add("Think", "gT_Keyboard", function()
	local ply = LocalPlayer()
	if ply.gT_StartKeyboard then
		if input.IsKeyTrapping() then
			local key = input.CheckKeyTrapping()
			if key != nil then 
				LocalPlayer():ChatPrint(key)
				SendKeyToServer(key)
			end
			if key == 83 or key == KEY_LALT then
				LocalPlayer():ChatPrint("END " )
				ply.gT_StartKeyboard = false
				EndKeyType()
			end
		else
			local key = input.CheckKeyTrapping()
			if key != nil then 
				
			end
			if key == 83 or key == KEY_LALT then
				LocalPlayer():ChatPrint("END " )
				ply.gT_StartKeyboard = false
			else
				input.StartKeyTrapping()
			end
		end
	end 
end)

net.Receive("gT_StartKeyType", function()
	local client = LocalPlayer()
	local entity = net.ReadEntity()
	client.gT_Entity = entity

	if ( IsValid(client.gT_TextEntry) ) then
		client.gT_TextEntry:Remove()
	end

	if ( IsValid(client.gT_Entity) ) then
		client.gT_Entity.consoleText = ""
	end
	client.gT_StartKeyboard = true
end)

net.Receive("gTSM_ColorBroadcast", function()
	local index = net.ReadUInt(16)
	local colorType = net.ReadUInt(8)
	local position = net.ReadInt(16)

	if ( !gTerminal[index] ) then
		gTerminal[index] = {};
	end;

	if (position and position != -1) then
		gTerminal[index][position] = {text = text, color = colorType};
	end;
end)

net.Receive("gTSM_FillBroadcast", function()
	local index = net.ReadUInt(16)
	local text = net.ReadString()
	local colorType = net.ReadUInt(8)
	local y = net.ReadInt(16)
	local x = net.ReadInt(16)
	print(y,x)
	if ( !gTerminal[index] ) then
		gTerminal[index] = {};
	end;

	local fillstring
	
	if y > 24 or y < 0 then
		return
	end
	
	if gTerminal[index][y] then
		fillstring = gTerminal[index][y]["text"]
	else
		fillstring = ""
	end

	while string.len(fillstring) < 50 do
		fillstring = fillstring .. " "
	end

	if string.len(text) + x > 50 then
		text = string.Left(text, 50 - (string.len(text) + x))
	end

	local s_start = string.Left(fillstring, x)
	local s_end   = string.reverse( string.Left(string.reverse(fillstring), 50 - (x + string.len(text))))
	
	fillstring = s_start .. text .. s_end

	gTerminal[index][y] = {text = fillstring, color = colorType};
end)