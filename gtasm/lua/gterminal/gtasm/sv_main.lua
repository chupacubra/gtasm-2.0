gTASM = gTASM or {}

include("sv_lexertasm.lua")
include("sv_ast.lua")
include("sv_commands.lua")
include("sv_memory.lua")
include("sv_prepar.lua")
include("sv_directive.lua")
include("sv_service.lua")

function gTASM:OpenDerm(entity,client,content,name)
	if ( !IsValid(entity) ) then
		return;
	end;
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

function gTerminal:ExecuteCode(entity,code,client)
	if entity == nil then
		return
	end

	function gTASM:InsertDBInMemory(entity,val,name)
		local cval = #val
		local b_start, b_end = entity.BANK:GetBoardBlock("POOL1")

		if cval + entity.dbLabel.endPos > b_end - 1 then

		else
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
					size     = posstart - (endpos - 1),
				}
			else
				table.insert(entity.dbLabel.dbList,{
					posStart = posstart,
					posEnd   = endpos - 1,
					size     = posstart - (endpos - 1),
				})
			end

			local block = entity.BANK:GetBlock("POOL1")
		end
	end

	gTASM:SetUpMemory(entity)
	
	entity.script = {}
	local i = 1
	local code = gTASM:PreparTheScript(code)
	
	for k,v in pairs(code) do
		local lex = lexer(v)
		local succes, ast, err, dat= pcall(astp,lex)

		if !succes then
			return
		end
		
		if ast == false then
			gTASM:ErrorScript(entity,err,dat)
			return
		end

		if ast.label then
			if ast.oper == nil then
				entity.jumpLabel[ast.label] = k
			elseif ast.oper == "db" then
				ast.arg["label"] = ast.label
			end
		end

		table.insert(entity.script,ast)
	end


	entity.str_i = 1

	hook.Add( "Tick", "CODEDELAY "..entity:EntIndex(), function()
		if entity == nil then
			entity.endscr = true
			return
		end

		if #entity.script < entity.str_i then
			entity.endscr = true
			return
		end

		if entity.endscr then 
			return
		end

		gTASM:ExecuteCommand(entity,entity.script[entity.str_i])

        --[[
		--gTASM:ExecuteCommand(entity,entity.script[entity.str_i])
		--local succes, e, data = pcall(gTASM.ExecuteCommand, entity,entity.script[entity.str_i])

		if !succes then
			--print("ERROR",e)
		end

		if e != nil then
			--gTASM:ErrorScript(entity,e,data)
		end
		--]]
		
		entity.str_i = entity.str_i  + 1
	end)
end
