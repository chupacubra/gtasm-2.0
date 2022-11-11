local gTerminal = gTerminal;

gTerminal.file = gTerminal.file or {};

function gTerminal.file:Initialize(entity)
	entity.fileCurrentDir = {};
end;

function gTerminal.file:ChangeDir(entity, key)
	local directory = entity.fileCurrentDir[key];

	if (key == "../") then
		if (entity.fileCurrentDir._parent) then
			directory = entity.fileCurrentDir._parent;
		end;
	end;

	if (directory and !directory.isFile) then
		entity.fileCurrentDir = directory;

		return true;
	end;

	gTerminal:Broadcast(entity, "Unable to find directory!");

	return false;
end;

function gTerminal.file:Write(entity, key, value)
	if (!entity.fileCurrentDir) then
		entity.fileCurrentDir = {};
	end;
	
	if (!key or key == "_parent") then
		gTerminal:Broadcast(entity, "Invalid name!");

		return false;
	end;

	if ( entity.fileCurrentDir[key] ) then
		gTerminal:Broadcast(entity, "Item already exists!");

		return false;
	end;		

	if (!value) then
		gTerminal:Broadcast(entity, "Invalid content!");

		return false;
	end;

	if (type(value) != "table") then
		value2 = {
			isFile = true,
			value = value,
			_parent = entity.fileCurrentDir;
		};
	end;

	if (value2) then
		entity.fileCurrentDir[key] = value2;
	else
		value._parent = entity.fileCurrentDir;

		entity.fileCurrentDir[key] = value;
	end;

	return true;
end;

function gTerminal.file:Rename(entity, previous, new)
	if ( !previous or !entity.fileCurrentDir[previous] ) then
		gTerminal:Broadcast(entity, "Unable to find file/directory!");

		return false;
	end;

	if (!new or new  == "_parent") then
		gTerminal:Broadcast(entity, "Invalid file/directory name!");

		return false;
	end;

	entity.fileCurrentDir[new] = entity.fileCurrentDir[previous];
	entity.fileCurrentDir[previous] = nil;

	return true;
end;

function gTerminal.file:Delete(entity, key)
	if ( !key or key == "_parent" or !entity.fileCurrentDir[key] ) then
		gTerminal:Broadcast(entity, "Invalid file/directory!");

		return false;
	end;

	entity.fileCurrentDir[key] = nil;

	return true;
end;

function gTerminal.file:Read(entity, key)
	if (!key or key == "_parent") then
		gTerminal:Broadcast(entity, "Invalid name!");

		return false;
	end;

	if ( !entity.fileCurrentDir[key] ) then
		gTerminal:Broadcast(entity, "Couldn't find file!");

		return false;
	end;

	if (!entity.fileCurrentDir[key].isFile or !entity.fileCurrentDir[key].value) then
		gTerminal:Broadcast(entity, "Invalid read type!");

		return false;
	end;

	return true, entity.fileCurrentDir[key].value;
end;