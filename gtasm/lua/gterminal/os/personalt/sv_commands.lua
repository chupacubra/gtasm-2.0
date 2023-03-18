local gTerminal = gTerminal;
local timer = timer;
local OS = OS;
local delay = 0

print(include("gterminal/gtasm/sv_main.lua"))

local function IsEmpty(t)
    if not t then
        return true
    end
    for _, _ in pairs(t) do
        return false
    end
    return true
end

OS:NewCommand(":help", function(client, entity, arguments)
	gTerminal:Broadcast(entity, "=============================");
	gTerminal:Broadcast(entity, "  PersonalOS Help Menu");
	gTerminal:Broadcast(entity, "");
	gTerminal:Broadcast(entity, "    COMMANDS:");

	for k, v in SortedPairs( OS:GetCommands() ) do
		gTerminal:Broadcast(entity, "     "..k.." - "..v.help);
	end;

	gTerminal:Broadcast(entity, "=============================");
end, "Provides a list of help.");

OS:NewCommand(":cls", function(client, entity)
	for i = 0, 25 do
		timer.Simple(i * 0.05, function()
			if ( IsValid(entity) ) then
				gTerminal:Broadcast(entity, "", MSG_COL_NIL, i);
			end;
		end);
	end;
end, "Clears the screen.");

OS:NewCommand(":cord", function(client, entity, arguments)
  if !entity.Cord then return end
  gTerminal:Broadcast(entity,"Cord INP = "..entity.Cord:GetINPV())
  if arguments[1] == "set" then
    entity.Cord:SendVal(arguments[2])
  end
end,"Plug setting")

OS:NewCommand(":gid", function(client, entity)
	gTerminal:Broadcast( entity, "TERMINAL ID => "..entity:EntIndex() );
end, "Gets the terminal ID.");

OS:NewCommand(":setpass", function(client, entity, arguments)
	local password = table.concat(arguments, " ");

	if (password and password != "") then
		entity.password = password;
		gTerminal:Broadcast(entity, "Password set to '"..entity.password.."'.");
	else
		entity.password = nil;
		gTerminal:Broadcast(entity, "Removed password.");
	end;
end, "Sets the password for the terminal.");

OS:NewCommand(":x", function(client, entity)
	gTerminal:Broadcast( entity, "SHUTTING DOWN..." );

	for k, v in pairs( player.GetAll() ) do
		v[ "pass_authed_"..entity:EntIndex() ] = nil;
	end;

	gTerminal.os:Call(entity, "ShutDown");
	
	timer.Simple(math.Rand(2, 5), function()
		if ( IsValid(entity) ) then
			for i = 0, 25 do
				if ( IsValid(entity) ) then
					gTerminal:Broadcast(entity, "");
				end;
			end;
			entity:SetActive(false);
		end;
	end);
end, "Turns off the terminal.");

OS:NewCommand(":tasm", function(client,entity,arguments)
	if ( !arguments[1] ) then
		gTerminal:Broadcast(entity, "");
		gTerminal:Broadcast(entity, " _______ _______ _______ _______ ");
		gTerminal:Broadcast(entity, "|_     _|   _   |     __|   |   |");
		gTerminal:Broadcast(entity, "  |   | |       |__     |       |");
		gTerminal:Broadcast(entity, "  |___| |___|___|_______|__|_|__|");
		gTerminal:Broadcast(entity, "");
		gTerminal:Broadcast(entity, "   gTerminal Assembler for you");
		gTerminal:Broadcast(entity, "  INFO:");
		gTerminal:Broadcast(entity, "    With gTASM you are able to write and execute scripts on this langauge");
		gTerminal:Broadcast(entity, "");
		gTerminal:Broadcast(entity, "  HELP:");
		gTerminal:Broadcast(entity, "    :tasm <filename> - Open script");
		gTerminal:Broadcast(entity, "    :tasm stop - Stop script");
	
	elseif(arguments[1] and arguments[1]!='stop' and arguments[1]!='dbg') then
		local key = arguments[1];
    if !key then gTerminal:Broadcast(entity, "No name") return end
		local success, value = gTerminal.file:Read(entity, key);
		
		if (success) then
			local code = util.JSONToTable(value)
    		gTerminal:ExecuteCode(entity,code,client)
		end
	elseif(arguments[1] == 'stop') then
		gTerminal:EndScript(entity)
	end 
end, "Terminal Assembler Programming language");	

OS:NewCommand(":gnet", function(client, entity, arguments)
	if ( !arguments[1] ) then
		gTerminal:Broadcast(entity, "Global Network Mark I");
		gTerminal:Broadcast(entity, "  INFO:");
		gTerminal:Broadcast(entity, "    With GNet you are able to communicate");
		gTerminal:Broadcast(entity, "    through user created networks with ease.");
		gTerminal:Broadcast(entity, "  HELP:");
		gTerminal:Broadcast(entity, "    :gnet j <network> - Joins a network.");
		gTerminal:Broadcast(entity, "    :gnet l - Leaves the network.");
		gTerminal:Broadcast(entity, "    :gnet ls - Lists all active networks.");
		gTerminal:Broadcast(entity, "    :gnet lu - Lists all users in the network.");
		gTerminal:Broadcast(entity, "    :gnet m <user ID> <text> - Sends a message to another user.");
	elseif (arguments[1] == "j") then
		if ( !arguments[2] ) then
			gTerminal:Broadcast(entity, "Invalid input for network!", GT_COL_ERR);

			return;
		end;

		if (entity.networkID) then
			gTerminal:Broadcast(entity, "You are already connected to Network '"..entity.networkID.."'", GT_COL_WRN);

			return;
		end;

		for k, v in pairs( ents.FindByClass(entity.ClassName) ) do
			if (v.isHost and v.networkID and v.networkID == arguments[2]) then
				if (v.netPassword) then
					if (!arguments[3] or arguments[3] != v.netPassword) then
						gTerminal:Broadcast(entity, "Incorrect password!", GT_COL_ERR);

						return;
					end;
				end;

				entity.networkID = v.networkID;

				gTerminal:Broadcast(entity, "You've joined Network '"..v.networkID.."'", GT_COL_SUCC);

				return;
			end;
		end;

		gTerminal:Broadcast(entity, "Unable to resolve network!", GT_COL_ERR);
	elseif (arguments[1] == "l") then
		if (!entity.networkID) then
			gTerminal:Broadcast(entity, "You aren't connected to a network!", GT_COL_ERR);

			return;
		end;

		for k, v in pairs( ents.FindByClass(entity.ClassName) ) do
			if (entity.isHost and v != entity and v.networkID and v.networkID == entity.networkID) then
				gTerminal:Broadcast(v, "Lost connection to active network!", GT_COL_WRN);

				v.networkID = nil;
			end;
		end;

		entity.isHost = nil;
		entity.networkID = nil;

		gTerminal:Broadcast(entity, "You have left your network.", GT_COL_SUCC);
	elseif (arguments[1] == "ls") then
		gTerminal:Broadcast(entity, "ACTIVE NETWORKS:");

		local num = 0;

		for k, v in pairs( ents.FindByClass(entity.ClassName) ) do
			if (v.isHost and v.networkID) then
				num = num + 1;

				if (v.netPassword) then
					gTerminal:Broadcast(entity, "    "..num..". "..v.networkID.." (PRIVATE)");
				else
					gTerminal:Broadcast(entity, "    "..num..". "..v.networkID.." (PUBLIC)");
				end;
			end;
		end;

		gTerminal:Broadcast(entity, "");
		gTerminal:Broadcast(entity, "    Found "..num.." active network(s).");
	elseif (arguments[1] == "lu") then
		if (!entity.networkID) then
			gTerminal:Broadcast(entity, "You aren't connected to a network!", GT_COL_ERR);

			return;
		end;

		gTerminal:Broadcast(entity, "ACTIVE USERS:");

		local num = 0;

		for k, v in pairs( ents.FindByClass(entity.ClassName) ) do
			if (v.networkID and v.networkID == entity.networkID) then
				if ( v:EntIndex() != entity:EntIndex() ) then
					num = num + 1;

					if (v.isHost) then
						gTerminal:Broadcast( entity, "    "..num..". (HOST) "..v:EntIndex() );
					else
						gTerminal:Broadcast( entity, "    "..num..". "..v:EntIndex() );
					end;
				end;
			end;
		end;

		gTerminal:Broadcast(entity, "");
		gTerminal:Broadcast(entity, "    Found "..num.." active user(s).");
	elseif (arguments[1] == "m") then
		if (!entity.networkID) then
			gTerminal:Broadcast(entity, "You aren't connected to a network!", GT_COL_ERR);

			return;
		end;

		if ( !arguments[2] or (!tonumber( arguments[2] ) and arguments[2] != "@") ) then
			gTerminal:Broadcast(entity, "Invalid input for user ID!", GT_COL_ERR);
			gTerminal:Broadcast(entity, "Use an ID of another terminal or use @ to message everyone.", GT_COL_ERR);

			return;
		end;

		local arguments2 = table.Copy(arguments);

		table.remove(arguments2, 1);
		table.remove(arguments2, 1);

		local message = table.concat(arguments2, " ");

		if (!message or message == "") then
			gTerminal:Broadcast(entity, "You didn't specify a message!", GT_COL_ERR);

			return;
		end;

		local index;

		if (arguments[2] != "@") then
			index = tonumber( arguments[2] );

			if (!index) then
				gTerminal:Broadcast(entity, "Invalid terminal ID!", GT_COL_ERR);

				return;
			end;
		end;

		local found = false;

		for k, v in pairs( ents.FindByClass(entity.ClassName) ) do
			if (!v.networkID) then
				continue;
			end;

			if ( v != entity and ( (v.isHost and v.networkID == entity.networkID) or ( v.networkID == entity.networkID and (arguments[2] == "@" or v:EntIndex() == index) ) ) ) then
				found = true;

				if (v.isHost and arguments[2] != "@") then
					gTerminal:Broadcast(v, entity:EntIndex().."@"..entity.networkID.." to "..arguments[2].."@"..entity.networkID.." => "..message, GT_COL_INFO);
				else
					gTerminal:Broadcast(v, entity:EntIndex().."@"..entity.networkID.." => "..message, GT_COL_INFO);
				end;
			end;
		end;

		if (arguments[2] != "@" and !found) then
			gTerminal:Broadcast(entity, "Couldn't find user!", GT_COL_ERR);

			return;
		end;

		gTerminal:Broadcast(entity, entity:EntIndex().."@"..entity.networkID.." => "..message, GT_COL_INFO);
	end;
end, "Global networking platform.");

OS:NewCommand(":math", function(client, entity, arguments)
	local class = arguments[1];

	if (!class) then
		gTerminal:Broadcast(entity, "Mathematics");
		gTerminal:Broadcast(entity, "  INFO:");
		gTerminal:Broadcast(entity, "    With math you can perform simple arithmetic.");
		gTerminal:Broadcast(entity, "  HELP:");
		gTerminal:Broadcast(entity, "    :math add <number> <number> - Adds two numbers.");
		gTerminal:Broadcast(entity, "    :math sub <number> <number> - Subtracts two numbers.");
		gTerminal:Broadcast(entity, "    :math mul <number> <number> - Multiplies two numbers.");
		gTerminal:Broadcast(entity, "    :math div <number> <number> - Divides two numbers.");
		gTerminal:Broadcast(entity, "    :math pow <number> <number> - The first number to the power of the second.");
	else
		local first = tonumber( arguments[2] );
		local second = tonumber( arguments[3] );

		if (first and second) then
			if (class == "add") then
				gTerminal:Broadcast( entity, first.." + "..second.." = "..(first + second), GT_COL_SUCC );
			elseif (class == "sub") then
				gTerminal:Broadcast( entity, first.." - "..second.." = "..(first - second), GT_COL_SUCC );
			elseif (class == "mul") then
				gTerminal:Broadcast( entity, first.." * "..second.." = "..(first * second), GT_COL_SUCC );
			elseif (class == "div") then
				gTerminal:Broadcast( entity, first.." / "..second.." = "..(first / second), GT_COL_SUCC );
			elseif (class == "pow") then
				gTerminal:Broadcast( entity, first.." ^ "..second.." = "..math.pow(first, second), GT_COL_SUCC );
			end;
		elseif (!first) then
			gTerminal:Broadcast(entity, "First number is invalid!", GT_COL_ERR);
		else
			gTerminal:Broadcast(entity, "Second number is invalid!", GT_COL_ERR);
		end;
	end;
end, "Peform simple arithmetic.");

OS:NewCommand(":gg", function(client, entity, arguments)
	local answer = math.random(1, 10);

	gTerminal:Broadcast(entity, "Guess a number from one to ten:");
	gTerminal:GetInput(entity, function(client, arguments)
		if ( !arguments[1] ) then
			gTerminal:Broadcast(entity, "You didn't give an answer! Game over.");

			return;
		end;

		if ( answer == tonumber( arguments[1] ) ) then
			gTerminal:Broadcast(entity, "You got it right! Good job.");
		else
			gTerminal:Broadcast(entity, "Wrong! The answer was "..answer..".");
		end;
	end);
end, "Guess a number from 1-10.");

OS:NewCommand(":f", function(client, entity, arguments)
	local command = arguments[1];

	if (!entity.fileCurrentDir) then
		gTerminal.file:Initialize(entity);
	end;

	if (!command) then
		gTerminal:Broadcast(entity, "File System");
		gTerminal:Broadcast(entity, "  INFO:");
		gTerminal:Broadcast(entity, "    This is the terminal's file system.");
		gTerminal:Broadcast(entity, "  HELP:");
		gTerminal:Broadcast(entity, "    :f ndir <name> - Creates a new directory.");	
		gTerminal:Broadcast(entity, "    :f r <old> <new> - Renames a file/directory.");	
		gTerminal:Broadcast(entity, "    :f d <name> - Deletes a file/directory.");
		gTerminal:Broadcast(entity, "    :f w <name> <value> - Writes a file.");
		gTerminal:Broadcast(entity, "    :f chdir <name> - Changes the current directory.");
		gTerminal:Broadcast(entity, "    :f l - Lists items in the current directory.");
		gTerminal:Broadcast(entity, "    :f rd <name> - Reads the content of a file.");
    	gTerminal:Broadcast(entity, "    :f dr <name> - Open a gTASM redactor.");
	elseif (command == "ndir") then
		local key = arguments[2];

		local success = gTerminal.file:Write( entity, key, {} );

		if (success) then
			gTerminal:Broadcast(entity, "Created new directory '"..key.."'.", GT_COL_SUCC);
		end;
	elseif (command == "r") then
		local key = arguments[2];
		local new = arguments[3];

		local success = gTerminal.file:Rename(entity, key, new);

		if (success) then
			gTerminal:Broadcast(entity, "Renamed '"..key.."' to '"..new.."'.", GT_COL_SUCC);
		end;
	elseif (command == "d") then
		local key = arguments[2];

		local success = gTerminal.file:Delete(entity, key);

		if (success) then
			gTerminal:Broadcast(entity, "Deleted '"..key.."'.", GT_COL_SUCC);
		end;
	elseif (command == "w") then
		local key = arguments[2];

		local arguments2 = arguments;

		table.remove(arguments2, 1);
		table.remove(arguments2, 1);

		local value = table.concat(arguments2, " ");
		local success = gTerminal.file:Write(entity, key, value);

		if (success) then
			gTerminal:Broadcast(entity, "Created new file '"..key.."'.", GT_COL_SUCC);
		end;
	elseif (command == "chdir") then
		local key = arguments[2];

		local success = gTerminal.file:ChangeDir(entity, key);

		if (success) then
			gTerminal:Broadcast(entity, "Changed directory to '"..key.."'.", GT_COL_SUCC);
		end;
	elseif (command == "l") then
		gTerminal:Broadcast(entity, "../");

		for k, v in SortedPairs(entity.fileCurrentDir) do
			if (k == "_parent") then
				continue;
			end;

			if (!v.isFile) then
				gTerminal:Broadcast(entity, "    "..k.."/");
			else
				gTerminal:Broadcast(entity, "    "..k);
			end;
		end;
	elseif (command == "rd") then
		
		local key = arguments[2];
		
		local success, value = gTerminal.file:Read(entity, key);
		
		if (success) then
			
			gTerminal:Broadcast( entity, tostring(value), GT_COL_INFO );
		end;

	elseif (command == "dr") then
		local name = arguments[2]
		if name == nil or name == "" then
      		gTerminal:Broadcast(entity,"No name")
      	return
    end
    
    local content = ""
    local key = arguments[2];
    local success, value = gTerminal.file:Read(entity, key)

    if (success) then
		local newFile = util.JSONToTable(value)
		content = table.concat(newFile,"\n")
    end

    gTASM:OpenDerm(entity,client,content,name)
	
end;
end, "Terminal file protocol.");

OS:NewCommand(":disk",function(client,entity,arguments)
	local command = arguments[1]
	if !command then
		gTerminal:Broadcast(entity, "Disk management system");
		gTerminal:Broadcast(entity, "  HELP:");
		gTerminal:Broadcast(entity, "    :disk id - Insert a disk.");	
		gTerminal:Broadcast(entity, "    :disk ed - Eject disk");	
		gTerminal:Broadcast(entity, "    :disk ad <name> - Add a file to disk.");
		gTerminal:Broadcast(entity, "    :disk dd <name> - Download file from disk.");
		gTerminal:Broadcast(entity, "    :disk dl - File list disk.");
		gTerminal:Broadcast(entity, "    :disk rd <name> - Delete file on disk.");
		gTerminal:Broadcast(entity, "    :disk n <name> - Set name disk.");
    
  elseif (command == "id") then
		if !entity.Disk then
			for k, v in pairs(ents.FindByClass("sent_disk")) do
				local dist = entity:GetPos():Distance(v:GetPos())
				if (dist <= 64) then
					entity.Disk = v
          entity.DiskO = v:GetOwner()
					v:Remove()
					gTerminal:Broadcast(entity,"A floppy disk is inserted")
					entity.DiskName = entity.Disk:GetNameD()
					entity.DiskData = entity.Disk:GetData()
				end
			end
			if entity.Disk == nil then return end
			gTerminal:Broadcast(entity,"Disk has been initialized")
		else
			gTerminal:Broadcast(entity,"Already inserted disk")
		end
	elseif (command == "dl") then
		if entity.Disk then
			gTerminal:Broadcast(entity,"Floppy disk - "..entity.DiskName )
			for k,v in pairs(entity.DiskData) do
				gTerminal:Broadcast(entity,"    "..k.." "..utf8.len(v).." bytes")
			end
			gTerminal:Broadcast(entity,"")
		else
			gTerminal:Broadcast(entity,"No disk")
		end
  elseif (command == "n") then
		if entity.Disk then
      local name = arguments[2]
      if name == nil then return end
			gTerminal:Broadcast(entity,"Floppy disk - "..entity.DiskName .. " => "..name )
      entity.DiskName = name
		else
			gTerminal:Broadcast(entity,"No disk")
		end
	elseif (command == "ad") then
		if entity.Disk then
			local k = arguments[2]
			local success, value = gTerminal.file:Read(entity, k);
			if(success) then
				if entity.DiskData[k] then
					local i = 1
          local kn = k
					while entity.DiskData[kn] do
						i=i+1
            kn = k .. "-"..i
          end
          k = kn
				end
				entity.DiskData[k] = value
				gTerminal:Broadcast(entity,"The file has been copied to a floppy disk")
			end
		else
			gTerminal:Broadcast(entity,"No disk")
		end
		
	elseif (command == "rd") then
		if entity.Disk then
			local k = arguments[2]
			if entity.DiskData[k] then
				entity.DiskData[k] = nil
				gTerminal:Broadcast(entity,"The file has been deleted in floppy disk")
			end
		else
			gTerminal:Broadcast(entity,"No disk")
		end
	elseif (command == "dd") then
		if entity.Disk then
			local k = arguments[2]
      if k == nil then return end
			if entity.DiskData[k] then
				local success = gTerminal.file:Write(entity, k, entity.DiskData[k]);
				if (success) then
					gTerminal:Broadcast(entity, "Download file from disk '"..k.."'.", GT_COL_SUCC);
				end;
			else
        gTerminal:Broadcast(entity, "No file on disk - '"..k.."'.")
			end
		else
			gTerminal:Broadcast(entity,"No disk")
		end
	elseif (command == "ed") then
		if entity.Disk then
			local disk = ents.Create( "sent_disk" )
			disk:SetPos( entity:LocalToWorld(Vector(0,0,25)) )
			disk:SetData(entity.DiskData)
			disk:SetNameD(entity.DiskName)
			disk:SetOwner(entity.DiskO)
			disk:Spawn()
			entity.Disk = nil
		else
			gTerminal:Broadcast(entity,"No disk")
		end
  end
end,"Disk management.")

OS:NewCommand(":claim", function(client, entity, arguments)

	local nearest = nil
	local range = 128
	local override = false
	local search_str = "Searching for nearest open I/O device..."
	
	if (arguments[1] == "override") then
		override = true
		search_str = "Searching for nearest overridable I/O device..."
	end
	
	gTerminal:Broadcast(entity, "")
	gTerminal:Broadcast(entity, search_str)
	
	for k, v in pairs(ents.FindByClass("sent_iodevice")) do
		if (!IsValid(v:GetComputer()) or override) then
			local dist = entity:GetPos():Distance(v:GetPos())
			if (dist <= range) then
				nearest = v
				range = dist
			end
		end
	end
	
	if (nearest == nil) then
		gTerminal:Broadcast(entity, "No I/O devices were found nearby.", GT_COL_WRN)
	else
		gTerminal:Broadcast(entity, "Nearest I/O device: [" .. nearest:EntIndex() .. "]")
		gTerminal:Broadcast(entity, "Claiming this device...")
		nearest:SetComputer(entity)
		gTerminal:Broadcast(entity, "I/O Device [" .. nearest:EntIndex() .. "] claimed.")
	end
	
end, "Connects to an unclaimed I/O device.")

OS:NewCommand(":wset", function(client, entity, arguments)

	local nearest = nil
	local range = 128
	
	for k, v in pairs(ents.FindByClass("sent_iodevice")) do
		if (v:GetComputer() == entity) then
			local dist = entity:GetPos():Distance(v:GetPos())
			if (dist <= range) then
				nearest = v
				range = dist
			end
		end
	end
	
	gTerminal:Broadcast(entity, "")
	
	if (nearest != nil) then
		if (arguments[1] == nil or arguments[2] == nil) then
			gTerminal:Broadcast(entity, "Usage(:set <letter> <string>)")
		else
			local input = string.lower(arguments[1])
			if (input == "a") then
				nearest:SetOP0(arguments[2])
			elseif (input == "b") then
				nearest:SetOP1(arguments[2])
			else
				gTerminal:Broadcast(entity, "Unknown output stream!", GT_COL_WRN)
			end
		end
	else
		gTerminal:Broadcast(entity, "Connection could not be made to I/O device!", GT_COL_WRN)
	end
	
end, "Sets a value in an I/O device.")

OS:NewCommand(":wget", function(client, entity, arguments)

	local nearest = nil
	local range = 128
	
	for k, v in pairs(ents.FindByClass("sent_iodevice")) do
		if (v:GetComputer() == entity) then
			local dist = entity:GetPos():Distance(v:GetPos())
			if (dist <= range) then
				nearest = v
				range = dist
			end
		end
	end
	
	if (nearest != nil) then
		gTerminal:Broadcast(entity, "")
		if (arguments[1] == nil) then
			gTerminal:Broadcast(entity, "Data returned from I/O Device:", GT_COL_INFO)
			gTerminal:Broadcast(entity, "A: " .. nearest:GetIP0())
			gTerminal:Broadcast(entity, "B: " .. nearest:GetIP1())
		else
			local input = string.lower(arguments[1])
			if (input == "a") then
				gTerminal:Broadcast(entity, "Data returned from I/O Device:", GT_COL_INFO)
				gTerminal:Broadcast(entity, "A: " .. nearest:GetIP0())
			elseif (input == "b") then
				gTerminal:Broadcast(entity, "Data returned from I/O Device:", GT_COL_INFO)
				gTerminal:Broadcast(entity, "B: " .. nearest:GetIP1())
			else
				gTerminal:Broadcast(entity, "Unknown input stream!", GT_COL_WRN)
			end
		end
	else
		gTerminal:Broadcast(entity, "")
		gTerminal:Broadcast(entity, "Connection could not be made to I/O device!", GT_COL_WRN)
	end
	
end, "Gets a value in an I/O device.")

OS:NewCommand(":isp", function(client, entity, arguments)
	local command = arguments[1];

	if (!command) then
		gTerminal:Broadcast(entity, "Instance Stream Protocol");
		gTerminal:Broadcast(entity, "  INFO:");
		gTerminal:Broadcast(entity, "    Allows for instance streaming of file from one terminal to another.");
		gTerminal:Broadcast(entity, "  HELP:");
		gTerminal:Broadcast(entity, "    :isp s <user> <file> - Sends a request for the user to accept the file.");	
	elseif (command == "s") then
		local index = tonumber( arguments[2] );
		local name = arguments[3];

		if (!index) then
			gTerminal:Broadcast(entity, "Invalid input for user ID!", GT_COL_ERR);

			return;
		end;

		if (!name) then
			gTerminal:Broadcast(entity, "Invalid input for file name!", GT_COL_ERR);

			return;
		end;

		if (entity.sendingFile) then
			gTerminal:Broadcast(entity, "You are currently making a request!", GT_COL_ERR);

			return;
		end;

		local success, value = gTerminal.file:Read(entity, name);

		if (success and value) then
			for k, v in pairs( ents.FindByClass(entity.ClassName) ) do
				if ( v.networkID and v.networkID == entity.networkID and (v:EntIndex() == index) ) then
					gTerminal:Broadcast(entity, "User validated, bridging connection...");
					gTerminal:Broadcast(v, "Incoming instance request, bridging connection...");

					if (!v.sendingFile) then
						entity.sendingFile = true;

						v.isp_Name = name;
						v.isp_Value = value;
						v.sendingFile = true;

						gTerminal:Broadcast(entity, "Connection finished, waiting for answer.");
						gTerminal:Broadcast(v, "Connection finished, waiting for answer.");
						gTerminal:Broadcast(v, "Would you like to accept file '"..v.isp_Name.."' from "..entity:EntIndex().."? (Y/N)");

						timer.Create("gT_file_req_"..entity:EntIndex(), 60, 1, function()
							if (IsValid(entity) and entity.sendingFile) then
								entity.sendingFile = nil;
								
								if ( IsValid(v) ) then
									v.isp_Name = nil;
									v.isp_Value = nil;
									v.sendingFile = nil;

									gTerminal:Broadcast(v, "Request timed out after one minute...", GT_COL_WRN);
								end;

								gTerminal:Broadcast(entity, "Request timed out after one minute...", GT_COL_WRN);
							end;
						end);

						gTerminal:GetInput(v, function(client, arguments)
							if (arguments[1] and string.lower( arguments[1] ) == "y") then
								gTerminal.file:Write(v, v.isp_Name, v.isp_Value);

								gTerminal:Broadcast(entity, "File has been sent, closed connection.", GT_COL_SUCC);
								gTerminal:Broadcast(v, "File has been sent, closed connection.", GT_COL_SUCC);
							else
								gTerminal:Broadcast(entity, "Request denied, closed connection.", GT_COL_WRN);
								gTerminal:Broadcast(v, "Connection denied, closed connection.", GT_COL_WRN);
							end;

							timer.Destroy( "gT_file_req_"..entity:EntIndex() );

							entity.sendingFile = nil;
							
							v.isp_Name = nil;
							v.isp_Value = nil;
							v.sendingFile = nil;

							return;
						end);
					else
						gTerminal:Broadcast(entity, "Request failed! Active connection already established.", GT_COL_WRN);
						gTerminal:Broadcast(v, "Request failed! Active connection already established.", GT_COL_WRN);
					end;

					return;
				end;
			end;

			gTerminal:Broadcast(entity, "Failed to find user!", GT_COL_ERR);
		end;
	end;
end, "Transfer files over a network.");

OS:NewCommand(":keyt", function(client, entity, arguments)
	print("test")
	gTerminal:Broadcast(entity,"Testing KeyType...")
	gTerminal:StartKeyType(entity,client)

end, "Test") 