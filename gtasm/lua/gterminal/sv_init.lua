include("sh_init.lua");
include("sv_filesystem.lua");
include("gtasm/sv_main.lua")
AddCSLuaFile("sh_init.lua");
util.AddNetworkString("gT_ActiveConsole");
util.AddNetworkString("gT_EndConsole");
util.AddNetworkString("gT_AddLine");
util.AddNetworkString("gT_EndTyping");
util.AddNetworkString("gT_RedDerm")
util.AddNetworkString("gT_SaveDerm")
util.AddNetworkString("gT_ListCommands")
util.AddNetworkString("gT_SendListCommands")
util.AddNetworkString("gT_SendListHelper")
util.AddNetworkString("gT_StartKeyType")
util.AddNetworkString("gT_ActiveKeyType")
util.AddNetworkString("gT_EndKeyType")

gTerminal = gTerminal or {};
gTerminal.os = gTerminal.os or {};

local gTerminal = gTerminal;
local net = net;

concommand.Add("derma", function( ply, cmd, args )
	net.Start("gT_RedDerm")
	net.WriteEntity(Entity(0))
	net.WriteString("")
	net.WriteString("")
	net.Send(ply)
end)

net.Receive( "gT_ListCommands", SendLC )

function gTerminal.os:Call(entity, name, ...)
	if ( IsValid(entity) ) then
		local key = entity:GetOS();
		local system = gTerminal.os[key];

		if (IsValid(entity) and system and system[name] and type( system[name] ) == "function") then
			local success, value = pcall(system[name], system, entity, ...);

			if (success) then
				return value;
			end;
		end;
	end;
end;


net.Receive("gT_SaveDerm", function(length, client)
	local entity = net.ReadEntity()
	local content = net.ReadString()
	local name = net.ReadString()

	if ( !IsValid(entity) ) then
		return;
	end;
	
	local file = string.Split(content,"\n")
	for k,v in pairs(file) do
		file[k] = v
	end
	
	table.remove(file)
	
	local value = util.TableToJSON(file)
	local success = gTerminal.file:Write(entity, name, value);
	
	if (success) then
		gTerminal:Broadcast(entity, "Created new file '"..name.."'.", GT_COL_SUCC);
	else
		gTerminal.file:Delete(entity, name);
		local success = gTerminal.file:Write(entity, name, value);
		if (success) then
			gTerminal:Broadcast(entity, "Created new file '"..name.."'.", GT_COL_SUCC);
		end
	end 
end)


function gTerminal:Broadcast(entity, text, colorType, position, xposition, onlyColor)
	if ( !IsValid(entity) ) then
		return;
	end;
	local index = entity:EntIndex();
	local output;
  if !onlyColor then
    onlyColor = false
  end
	if (string.len(text) > 50) then
		output = {};

		local expected = math.floor(string.len(text) / 50);

		for i = 0, expected do
			output[i + 1] = string.sub(text, i * 50, (i * 50) + 49);
		end;
	end;

	if (output) then
		for k, v in ipairs(output) do
			net.Start("gT_AddLine");
				net.WriteUInt(index, 16);
				net.WriteString(v);
				net.WriteUInt(colorType or GT_COL_MSG, 8);

				if (position) then
					net.WriteInt(position + (k - 1), 16);
				else
					net.WriteInt(-1, 16);
				end;
				if (xposition) then
					net.WriteInt(xposition,7);
				else
					net.WriteInt(0,7);
				end;
        net.WriteBool((onlyColor) or false)
			net.Broadcast();
		end;
	else
		net.Start("gT_AddLine");
			net.WriteUInt(index, 16);
			net.WriteString(text);
			net.WriteUInt(colorType or GT_COL_MSG, 8);
			net.WriteInt(position or -1, 16);
			if (xposition) then
				net.WriteInt(xposition,7);
			else
				net.WriteInt(0,7);
			end;
      net.WriteBool((onlyColor) or false)
		net.Broadcast();
	end;
end;

function gTerminal:GetInput(entity, Callback)
	entity.acceptingInput = true;
	entity.inputCallback = Callback;
end;

net.Receive("gT_EndConsole", function(length, client)
	local index = net.ReadUInt(16);
	local entity = Entity(index);
	local text = net.ReadString();

	if (IsValid(entity) and entity.GetUser and IsValid( entity:GetUser() ) and entity:GetUser() == client) then
		if (text == "" or text == " ") then
			entity:SetUser(nil);

			net.Start("gT_EndTyping");
			net.Send(client);

			return;
		end;
		
		if ( entity.password and !client["pass_authed_"..index] ) then
			if (text == entity.password) then
				client["pass_authed_"..index] = true;

				gTerminal:Broadcast(entity, "Password accepted.");

				return;
			else
				gTerminal:Broadcast(entity, "Please enter your password:");

				return;
			end;
		end;

		if (string.sub(text, 1, 1) == ":") then
			local system = gTerminal.os[ entity:GetOS() ];

			if (system) then
				for k, v in pairs( system:GetCommands() ) do
					local command = string.sub( string.lower(text), 1, string.len(k) );
					
					if (k == command) then
						local text2 = string.sub(text, string.len(command) + 2);
						local quote = (string.sub(text2, 1, 1) != "\"");
						local arguments = {};

						for chunk in string.gmatch(text2, "[^\"]+") do
							quote = !quote;

							if (quote) then
								table.insert(arguments, chunk);
							else
								for chunk in string.gmatch(chunk, "[^ ]+") do
									table.insert(arguments, chunk);
								end;
							end;
						end;

						local success, value = pcall(v.Callback, client, entity, arguments);

						if (success) then
							gTerminal:Broadcast(entity, text, GT_COL_CMD);
						else
							gTerminal:Broadcast(entity, value, GT_COL_ERR);
						end;

						return;
					end;
				end;

				text = "Invalid command! ("..string.sub(text, 2)..")";
			else
				gTerminal:Broadcast(entity, "System error from user response!", GT_COL_INTL);

				return;
			end;
		end;

		if (entity.acceptingInput) then
			local quote = (string.sub(text, 1, 1) != "\"");
			local arguments = {};

			for chunk in string.gmatch(text, "[^\"]+") do
				quote = !quote;

				if (quote) then
					table.insert(arguments, chunk);
				else
					for chunk in string.gmatch(chunk, "[^ ]+") do
						table.insert(arguments, chunk);
					end;
				end;
			end;

			local Callback = entity.inputCallback;

			if (Callback and arguments) then
				Callback(client, arguments);
			end;

			entity.acceptingInput = nil;
			entity.inputCallback = nil;

			return;
		end;
    if !entity.INPF then
      local finalized = string.lower( entity:GetUser():Name() ).."@"..entity:EntIndex().." => "..tostring(text);
      gTerminal:Broadcast(entity, finalized, GT_COL_NIL);
    end
	end;
end);

local files, folders = file.Find("gterminal/os/*", "LUA");

for k, v in pairs(folders) do
	OS = {};
		OS.commands = {};

		function OS:NewCommand(name, Callback, help)
			self.commands[name] = {Callback = Callback, help = help};
		end;

		function OS:GetCommands()
			return self.commands;
		end;
		
		include("os/"..v.."/sv_init.lua");

		gTerminal.os[ OS:GetUniqueID() ] = OS;
	OS = nil;
end;

net.Receive("gT_ActiveKeyType", function()
	local entity = net.ReadEntity()
	local key = net.ReadInt(9)
	--print(key,"IS WRITEN")
	--gTerminal:Broadcast(entity,"KEY IS PRESSED: "..key..tostring(entity.FLAGS.ink))
	if entity.FLAGS.ink then
		--print("write to mem",key)
		entity.BANK:WriteS(entity.regLabel.INS,to8int(key))
	end
end)

function gTerminal:StartKeyType(ent,ply)
	--print("SEND TO CLIENT")
	net.Start("gT_StartKeyType")
	net.WriteEntity(ent)
	net.Send(ply)
end

net.Receive("gT_EndKeyType" ,function()
	local entity = net.ReadEntity()
	entity:SetKeyType(false)
	entity:SetUser(nil)
	if entity.FLAGS.ink then
		entity.FLAGS.ink = false
		entity.BANK:WriteS(entity.regLabel.INK,to8int(0))
	end
	--print("end keytype")
end)

print(cookie.GetString( "hide_newslist"))
MsgC(Color(0, 255, 0), "Initialized gTASM!\n");