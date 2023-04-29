gTASM = {}

include("sv_enum.lua")
include("sv_lexertasm.lua")
include("sv_ast.lua")
include("sv_commands.lua")
include("sv_concmd.lua")
include("sv_memory.lua")
include("sv_prepar.lua") 
include("sv_directive.lua")
include("sv_service.lua")
include("sv_netstr.lua") 

util.AddNetworkString("gTSM_FillBroadcast")
util.AddNetworkString("gTSM_ColorBroadcast")


function gTASM:Logger(typeL, data) -- if script accidentaly freeze the game this can help you
	if typeL == "start" then
		local f = file.Open( "gtasmLog.txt", "w", "DATA" )
		f:Write("START LOG "..data[1].."\n")
		f:Close()
	elseif typeL == "code" then
		file.Append( "gtasmLog.txt","\nCODE: \n")
		for k,v in pairs(data[1]) do
			file.Append( "gtasmLog.txt",k.."  "..v.."\n")
		end
		file.Append( "gtasmLog.txt","\nEND CODE\n")
	elseif typeL == "startScript" then
		file.Append( "gtasmLog.txt","\nSTART SCRIPT:\n")
	elseif typeL == "oper" then
		file.Append( "gtasmLog.txt",data[1].." "..data[2].."\n")
	end
end

function gTASM:SetRegister(entity,name,val,size)
	local address = entity.regLabel[name]

	if address == nil then
		return
	end

	entity.BANK:WriteS(address,tobinval(val,size or 1))
end

function gTASM:GetRegister(entity, name, size)
	local adres= entity.regLabel[name]

	if adres == nil then
		return
	end

	local val = entity.BANK:ReadS(adres, size or 1)

	return val
end

function gTASM:StackPush(entity, val, size)
	local serv_start,serv_end = entity.BANK:GetBoardBlock("STACK")
	local stack_stat = tonumber(gTASM:GetRegister(entity,"SP", 2),2)

	if serv_start + stack_stat > serv_end then
		gTASM:ErrorScript(entity, GT_E_STACK_OVER,{LAST_PUSH = val})
		return
	end

	entity.BANK:WriteS(serv_start + stack_stat, tobinval(val, size or 1))
	gTASM:SetRegister(entity, "SP", stack_stat + (size or 1), 2)
end

function gTASM:StackPop(entity, size)
	local serv_start,serv_end = entity.BANK:GetBoardBlock("STACK")
    local stack_stat = tonumber(gTASM:GetRegister(entity,"SP", 2),2)
    
	if stack_stat != 0 then
        stack_stat = stack_stat - (size or 1)
		if stack_stat < 0 then
			gTASM:ErrorScript(entity, GT_E_STACK_OVER,{LAST_POP_SIZE = size})
			return
		end
    else
		gTASM:ErrorScript(entity, GT_E_STACK_OVER,{LAST_POP_SIZE = size})
	end
	
    
	local var = tonumber(entity.BANK:ReadS(serv_start + stack_stat, size or 1),2)
	gTASM:SetRegister(entity, "SP", stack_stat, 2)
    entity.BANK:WriteS(serv_start + stack_stat, tobinval(0,size or 1))
	
	return var
end


function gTASM:OpenDerm(entity,client,content,name)
	if ( !IsValid(entity) ) then
		return
	end

	net.Start("gT_RedDerm")
	net.WriteEntity(entity)
	net.WriteString(content)
	net.WriteString(name)
	net.Send(client)
end

function gTASM:ErrorScript(entity,error,stat)
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

	if nearest != nil then
		nearest:SetOP0("")
		nearest:SetOP1("")
	end

	if type(error) == "number"  then
		gTerminal:EndScript(entity)
		gTerminal:Broadcast(entity,"[gTASM] "..GTASM_ERROR_LIST[error],GT_COL_ERR)
	else
		gTerminal:EndScript(entity)
		gTerminal:Broadcast(entity,"[!] "..error,GT_COL_ERR)
	end

	if stat then
		gTerminal:Broadcast(entity,"Some info")
		for k,v in pairs(stat) do 
			gTerminal:Broadcast(entity,k..": "..v)
		end
	end

	gTerminal:Broadcast(entity,"")
end

function gTerminal:EndScript(entity)
	if !entity then 
		return 
	end
	entity.endscr = true
	entity.INPF = false
	entity.input = false
end

function gTASM:InsertDBInMemory(entity,val,name)
	local cval = #val
	local b_start, b_end = entity.BANK:GetBoardBlock("POOL2")

	if cval  + entity.dbLabel.endPos <= b_end - 1 then

		local posstart  = entity.dbLabel.endPos 
		local endpos = entity.dbLabel.endPos + cval + 1 

		for i = 0,cval-1 do
			entity.BANK:WriteS(entity.dbLabel.endPos + i,val[i + 1])
		end

		entity.dbLabel.endPos = endpos

		if name then
			entity.dbLabel.dbList[name] = {
				posStart = posstart,
				posEnd   = endpos - 1,
				size     = endpos - posstart,
			}
		else
			table.insert(entity.dbLabel.dbList,{
				posStart = posstart,
				posEnd   = endpos - 1,
				size     = endpos - posstart,
			})
		end
	end
end

function gTerminal:ExecuteCode(entity,code,client)
	if !IsValid(entity) then
		return
	end

	gTASM:SetUpMemory(entity)
	
	entity.script = {}

	local i = 1
	local code = gTASM:PreparTheScript(code)

	for k,v in pairs(code) do
		local lex = lexer(v)
		local succes, ast, err, dat= pcall(newast,lex[1])

		if !succes then
			gTASM:ErrorScript(entity, GT_E_COMPILE)
			return
		end
		
		if ast == false then
			gTASM:ErrorScript(entity,err,{LINE = k})
			return
		end

		if ast.label then
			if ast.oper == nil then
				entity.jumpLabel[ast.label] = k
			elseif ast.oper == "db" or ast.oper == "dd"  then
				ast.arg["label"] = ast.label
			end
		end
		table.insert(entity.script,ast)
	end
	
	entity.str_i = 1
	local ent_id = entity:EntIndex()
	
	hook.Add( "Tick", "gT_"..ent_id, function()
		if !entity:IsValid() then
			hook.Remove( "Tick", "gT_"..ent_id )
			return
		end

		if #entity.script < entity.str_i then
			entity.endscr = true
			return
		end

		if entity.endscr then
			hook.Remove( "Tick", "gT_"..ent_id )
			return
		end

		local command = entity.script[entity.str_i]

		local err, ed = gTASM:ExecuteCommand(entity, command)

		if err != nil then
			hook.Remove( "Tick", "gT_"..ent_id )
			ed["LINE"] = entity.str_i
			gTASM:ErrorScript(entity, err, ed)
		end

		gTASM:SetRegister(entity,"IP",entity.str_i)
		
		if entity.str_i == nil then
			entity.endscr = true
		end

		entity.str_i = entity.str_i  + 1
	end)
end


function gTASM:FillBroadcast(entity, text, colorType, y, x)
	local index = entity:EntIndex()

	net.Start("gTSM_FillBroadcast")
	net.WriteUInt(index, 16)
	net.WriteString(text)
	net.WriteUInt(colorType or GT_COL_MSG, 8)
	net.WriteInt(y or -1, 16)
	net.WriteInt(x or 0, 16)
	net.Broadcast()
end

function gTASM:ColorBroadcast(entity, color, y)
	local index = entity:EntIndex()

	net.start("gTSM_ColorBroadcast")
	net.WriteUInt(index, 16)
	net.WriteUInt(colorType or GT_COL_MSG, 8)
	net.WriteInt(y or -1, 16)
	net.Broadcast()
end


hook.Add("gTASM", "MemoryIndexE", function(id, err)
	local entity = Entity(id)
	gTASM:ErrorScript(entity, GT_E_MEM_ADDRES, {INV_ADR = err[1], SIZE = err[2], LINE = entity.str_i})
end)

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

	--[[remove the \]]
	
	table.remove(file)
	local value = util.TableToJSON(file)
	
	value = string.gsub(value,"\r","")
	
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

function gTerminal:GetInput(entity, Callback)
	entity.acceptingInput = true;
	entity.inputCallback = Callback;
end;


net.Receive("gT_ActiveKeyType", function()
	local entity = net.ReadEntity()
	local key = net.ReadInt(9)

	if entity.FLAGS.ink then
		entity.BANK:WriteS(entity.regLabel.INS,to8int(key))
	end
end)

function gTerminal:StartKeyType(ent,ply)
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
end)
