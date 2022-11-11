include("sh_init.lua");
--include("cl_luapad_editor.lua")
include("cl_redactor.lua")

local gTASM = {}
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
	print(ply.gT_Entity)
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
	local xposition = net.ReadInt(7)
  local onlyColor = net.ReadBool()
	if ( !gTerminal[index] ) then
		gTerminal[index] = {};
	end;
  if onlyColor then
    if gTerminal[index][position] then
      gTerminal[index][position]["color"] = colorType
    end
    return
  end
	if !position or position == -1 then
		if xposition == 0 then
			table.insert( gTerminal[index], {text = text, color = colorType} );
		else
			table.insert( gTerminal[index], {text = text, color = colorType} );
		end 
	else
		if xposition == 0 then
			gTerminal[index][position] = {text = text, color = colorType}
		else
			local str = gTerminal[index][position]["text"]
			local nlen = 51 - string.len(str)
			if nlen > 0 then
				for i=0,nlen do
					str = str .. " "
				end
			end 
			local t = {}
      if string.len(text)<1 then
        for i=1,string.len(str) do
          table.insert(t,string.sub(str,i,i))
        end
        table.remove(t,xposition)
        table.insert(t,xposition,text)
        local newStr = ""
        for k,v in pairs(t) do
          newStr = newStr .. t[k]
        end
        gTerminal[index][position] = {text = newStr,color = colorType}
      else
        local tl = string.len(text)
          if tl + xposition > 51 then
            text = string.sub(text,0,51-xposition)
          end
          for i=1,string.len(str) do
            table.insert(t,string.sub(str,i,i))
          end
          for i=1,tl do
            table.remove(t,xposition)
          end
          for i=tl,1,-1 do
            table.insert(t,xposition,string.sub(text,i,i))
          end
        newStr = ""
        for k,v in pairs(t) do
          newStr = newStr .. t[k]
        end
        gTerminal[index][position] = {text = newStr,color = colorType}
      end
		end 
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

net.Receive("gT_StartKeyType",function()
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
