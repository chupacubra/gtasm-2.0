include("sv_sysinter.lua")
gTASM = gTASM or {}
--[[
local function ConvertString(str)  
    local function comp(...)
        return {...}
    end

    local rez = comp(string.byte(str, 1,string.len(str)))
    return rez
end

local function ISDB(entity,name)
    if entity.dbLabel.dbList[name] then
        return true
    end
    return false
end

local function to8int(vall)
    local val = tonumber(vall) 
	while val > 255 do
		val = val - 255
	end
	while val < 0 do
		val = val + 255
	end
    return tobase(tonumber(val),2,8)
end

local function strtonum(str)
    if string.len(str) == 0 then return 0 end

    local arr = string.ToTable(str)

    for k,v in pairs(arr) do
        local ch = string.byte(arr[k])
        local bn  = table.concat(to8int(ch))
        arr[k] = bn
    end
    
    return table.concat()
end

--]]
function gTASM:GetAddresMem(ent,arg)
    if arg.n_type == GTASM_REG then
        if ent.regLabel[arg.data] then
            return ent.regLabel[arg.data]
        elseif ent.dbLabel.dbList[arg.data] then
            return ent.dbLabel.dbList[arg.data]["posStart"]
        end

    elseif arg.n_type == GTASM_VAR then
        return ent.memLabel[arg.data]

    elseif arg.n_type == GTASM_ADDR then
        if arg.data[1]["n_type"] < GTASM_ALLNUM then
            return arg.data[1]["convert"] or arg.data[1]["data"]

        elseif arg.data[1]["n_type"] > GTASM_ALLMEM then
            local addr = gTASM:GetAddresMem(ent,arg.data[1])

            local isdb = ISDB(ent,arg.data[1]["data"])
            local rez

            if isdb then
                rez = addr
            else
                rez = tonumber(ent.BANK:ReadS(addr,1),2)
            end
            return rez,isdb
        end
    end
end

function gTASM:ExecuteCommand(ent,cmd)
    local name = cmd.oper
    local arg  = cmd.arg

    if self.cmds[name] == nil then
        return  0
    end

    local allowtype = self.cmds[name]["tval"]
    
    if allowtype.size_nolimit == true then 
        for k,v in pairs(arg) do
            for a,b in pairs(allowtype[1]) do
                if b == GTASM_ALL then
                    break
                end
                if v.n_type == b then
                    break
                elseif a == #allowtype[k] then
                    return 6,{ARG_ID = k}
                end
            end
        end
    else
        for k,v in pairs(arg) do
            for a,b in pairs(allowtype[k]) do
                if b == GTASM_ALL or b == GTASM_NOALL then
                    break
                end

                if b == GTASM_ALLNUM then
                    if v.n_type < GTASM_ALLNUM then
                        break
                    end
                end

                if v.n_type == b then
                    break
                elseif a == #allowtype[k] then
                    return 6,{ARG_ID = k}
                end
            end
        end
    end
    local result = self.cmds[name]["func"](ent,arg) -- OK == 1,0, ERR == -1,NUM_ERROR
end


function gTASM:NewOper(name,dtype,tval,f)
    self.cmds = self.cmds or {}
    local cmd = {}

    cmd.dtype = dtype
    cmd.tval  = tval
    cmd.func = f

    self.cmds[name] = cmd
end


gTASM:NewOper("mov","Memory",{
    {GTASM_VAR, GTASM_REG, GTASM_ADDR},
    {GTASM_ALL}
},function(entity,arg)
    local toaddr = gTASM:GetAddresMem(entity,arg[1])
    local var,from

    if arg[2]["n_type"] < GTASM_ALLMEM then

        if arg[2]["n_type"] == GTASM_STR then
            var = strtonum(arg[2]["data"])
        else
            var = arg[2]["convert"] or arg[2]["data"]
        end

    else
        local fromaddr,db = gTASM:GetAddresMem(entity,arg[2])
        
        if db then
            var = fromaddr
        else
            var = tonumber(entity.BANK:ReadS(fromaddr,1),2)
        end
        from = fromaddr
    end

    entity.BANK:WriteS(toaddr,to8int(var))
end)


gTASM:NewOper("add","Math",{
    {GTASM_VAR, GTASM_REG, GTASM_ADDR},
    {GTASM_ALL}
},function(entity,arg)
    local toaddr = gTASM:GetAddresMem(entity,arg[1])
    local var

    if arg[2]["n_type"] < GTASM_ALLMEM then
        if arg[2]["n_type"] == GTASM_STR then

        else
            var = arg[2]["convert"] or arg[2]["data"]
        end
    else
        local fromaddr = gTASM:GetAddresMem(entity,arg[2])
        var = tonumber(entity.BANK:ReadS(fromaddr,1),2)
    end

    local var2 = tonumber(entity.BANK:ReadS(toaddr,1),2)
    entity.BANK:WriteS(toaddr,to8int(var2 + var))
end)


gTASM:NewOper("sub","Math",{
    {GTASM_VAR, GTASM_REG, GTASM_ADDR},
    {GTASM_ALL}
},function(entity,arg)
    local toaddr = gTASM:GetAddresMem(entity,arg[1])
    local var

    if arg[2]["n_type"] < GTASM_ALLMEM then
        if arg[2]["n_type"] == GTASM_STR then

        else
            var = arg[2]["convert"] or arg[2]["data"]
        end
    else
        local fromaddr = gTASM:GetAddresMem(entity,arg[2])
        var = tonumber(entity.BANK:ReadS(fromaddr,1),2)
    end

    local var2 = tonumber(entity.BANK:ReadS(toaddr,1),2)
    entity.BANK:WriteS(toaddr,to8int(var2 - var))
end)

gTASM:NewOper("mul","Math",{
    {GTASM_VAR, GTASM_REG, GTASM_ADDR},
    {GTASM_ALL}
},function(entity,arg)
    local toaddr = gTASM:GetAddresMem(entity,arg[1])
    local var
    if arg[2]["n_type"] < GTASM_ALLMEM then
        if arg[2]["n_type"] == GTASM_STR then

        else
            var = arg[2]["convert"] or arg[2]["data"]
        end
    else
        local fromaddr = gTASM:GetAddresMem(entity,arg[2])
        var = tonumber(entity.BANK:ReadS(fromaddr,1),2)
    end

    local var2 = tonumber(entity.BANK:ReadS(toaddr,1),2)
    entity.BANK:WriteS(toaddr,to8int(var2 * var))
end)

gTASM:NewOper("div","Math",{
    {GTASM_VAR, GTASM_REG, GTASM_ADDR},
    {GTASM_ALL}
},function(entity,arg)
    local toaddr = gTASM:GetAddresMem(entity,arg[1])
    local var

    if arg[2]["n_type"] < GTASM_ALLMEM then
        if arg[2]["n_type"] == GTASM_STR then

        else
            var = arg[2]["convert"] or arg[2]["data"]
        end
    else
        local fromaddr = gTASM:GetAddresMem(entity,arg[2])
        var = tonumber(entity.BANK:ReadS(fromaddr,1),2)
    end

    local var2 = tonumber(entity.BANK:ReadS(toaddr,1),2)
    entity.BANK:WriteS(toaddr,to8int(math.floor(var2 / var)))
end)

gTASM:NewOper("and","Math",{
    {GTASM_VAR, GTASM_REG, GTASM_ADDR},
    {GTASM_ALL}
},function(entity,arg)
    local toaddr = gTASM:GetAddresMem(entity,arg[1])
    local var

    if arg[2]["n_type"] < GTASM_ALLMEM then
        if arg[2]["n_type"] == GTASM_STR then

        else
            var = arg[2]["convert"] or arg[2]["data"]
        end
    else
        local fromaddr = gTASM:GetAddresMem(entity,arg[2])
        var = tonumber(entity.BANK:ReadS(fromaddr,1),2)
    end

    local var2 = tonumber(entity.BANK:ReadS(toaddr,1),2)
    entity.BANK:WriteS(toaddr,to8int(bit.band( var2 , var)))
end)

gTASM:NewOper("or","Math",{
    {GTASM_VAR, GTASM_REG, GTASM_ADDR},
    {GTASM_ALL}
},function(entity,arg)
    local toaddr = gTASM:GetAddresMem(entity,arg[1])
    local var

    if arg[2]["n_type"] < GTASM_ALLMEM then
        if arg[2]["n_type"] == GTASM_STR then

        else
            var = arg[2]["convert"] or arg[2]["data"]
        end
    else
        local fromaddr = gTASM:GetAddresMem(entity,arg[2])
        var = tonumber(entity.BANK:ReadS(fromaddr,1),2)
    end

    local var2 = tonumber(entity.BANK:ReadS(toaddr,1),2)
    entity.BANK:WriteS(toaddr,to8int(bit.bor(var2 ,var)))
end)

gTASM:NewOper("xor","Math",{
    {GTASM_VAR, GTASM_REG, GTASM_ADDR},
    {GTASM_ALL}
},function(entity,arg)
    local toaddr = gTASM:GetAddresMem(entity,arg[1])
    local var

    if arg[2]["n_type"] < GTASM_ALLMEM then
        if arg[2]["n_type"] == GTASM_STR then

        else
            var = arg[2]["convert"] or arg[2]["data"]
        end
    else
        local fromaddr = gTASM:GetAddresMem(entity,arg[2])
        var = tonumber(entity.BANK:ReadS(fromaddr,1),2)
    end

    local var2 = tonumber(entity.BANK:ReadS(toaddr,1),2)
    entity.BANK:WriteS(toaddr,to8int(bit.bxor(var2 , var)))
end)

gTASM:NewOper("inc","Math",{
    {GTASM_VAR, GTASM_REG, GTASM_ADDR}
},function(entity,arg)
    local toaddr = gTASM:GetAddresMem(entity,arg[1])
    local var2 = tonumber(entity.BANK:ReadS(toaddr,1),2)
    entity.BANK:WriteS(toaddr,to8int(var2 + 1))
end)

gTASM:NewOper("dec","Math",{
    {GTASM_VAR, GTASM_REG, GTASM_ADDR}
},function(entity,arg)
    local toaddr = gTASM:GetAddresMem(entity,arg[1])
    local var2 = tonumber(entity.BANK:ReadS(toaddr,1),2)
    entity.BANK:WriteS(toaddr,to8int(var2 - 1))
end)

gTASM:NewOper("rand","Math",{
    {GTASM_VAR, GTASM_REG, GTASM_ADDR},
},function(entity,arg)
    local toaddr = gTASM:GetAddresMem(entity,arg[1])

    entity.BANK:WriteS(toaddr,to8int(math.random(0, 100)))
end)

gTASM:NewOper("not","Math",{
    {GTASM_VAR, GTASM_REG, GTASM_ADDR}
},function(entity,arg)
    local toaddr = gTASM:GetAddresMem(entity,arg[1])
    local var2 = tonumber(entity.BANK:ReadS(toaddr,1),2)

    entity.BANK:WriteS(toaddr,to8int(bit.bnot(var2)))
end)

gTASM:NewOper("cmp","Logic",{
    {GTASM_ALL},
    {GTASM_ALL}
},function(entity,arg)
    local addr1 = gTASM:GetAddresMem(entity,arg[1])
    local var1 = tonumber(entity.BANK:ReadS(addr1,1),2)
    local var

    if arg[2]["n_type"] < GTASM_ALLMEM then
        if arg[2]["n_type"] < GTASM_ALLNUM then
            var = arg[2]["convert"] or arg[2]["data"]
        else
            var = arg[2]["convert"] or arg[2]["data"]
        end
    else
        local fromaddr = gTASM:GetAddresMem(entity,arg[2])
        var = tonumber(entity.BANK:ReadS(fromaddr,1),2)
    end

    var1 = var1 - var
    local zf,cf
    if var1 == 0 then
        zf = 1
        cf = 0
    elseif var1 < 0 then
        zf = 0
        cf = 1
    elseif var1 > 0 then
        zf = 0
        cf = 0
    end

    entity.BANK:WriteS(entity.regLabel.CF,to8int(cf))
    entity.BANK:WriteS(entity.regLabel.ZF,to8int(cf))

    entity.FLAGS.cf = cf
    entity.FLAGS.zf = zf
end)

gTASM:NewOper("db","Memory",{
    {GTASM_ALL}, -- no ne pamyat
    size_nolimit = true
},function(entity,arg)
    local rez = {}
    local labl

    if arg.label then
        labl = arg.label
        arg.label = nil
    end

    for k,v in pairs(arg) do
        if v.n_type < GTASM_ALLNUM then
            table.insert(rez,to8int(v.convert or tonumber(v.data)))

        elseif v.n_type == GTASM_STR then
            local str = ConvertString(v.data[1]["data"])

            for k,v in pairs(str) do
                table.insert(rez,to8int(v))
            end

        end
    end
    gTASM:InsertDBInMemory(entity,rez,labl)
end)

gTASM:NewOper("jmp","Logic",{
    {GTASM_STR},
},function(entity,arg)
    local label = arg[1]["data"][1]["data"]
    if entity.jumpLabel[label] then
        entity.str_i = entity.jumpLabel[label]
    end
end)

gTASM:NewOper("je","Logic",{
    {GTASM_STR},
},function(entity,arg)
    local label = arg[1]["data"][1]["data"]
    if entity.jumpLabel[label] then
        if entity.FLAGS.zf == 1 then
            entity.str_i = entity.jumpLabel[label]
        end
    end
end)

gTASM:NewOper("jne","Logic",{
    {GTASM_STR},
},function(entity,arg)
    local label = arg[1]["data"][1]["data"]
    if entity.jumpLabel[label] then
        if entity.FLAGS.zf == 0 then
            entity.str_i = entity.jumpLabel[label]
        end
    end
end)

gTASM:NewOper("jb","Logic",{
    {GTASM_STR},
},function(entity,arg)
    local label = arg[1]["data"][1]["data"]
    if entity.jumpLabel[label] then
        if entity.FLAGS.cf == 1 then
            entity.str_i = entity.jumpLabel[label]
        end
    else
    end
end)

gTASM:NewOper("ja","Logic",{
    {GTASM_STR},
},function(entity,arg)
    local label = arg[1]["data"][1]["data"]
    if entity.jumpLabel[label] then
        if entity.FLAGS.cf == 0  and entity.FLAGS.zf == 0 then
            entity.str_i = entity.jumpLabel[label]
        end
    end
end)

gTASM:NewOper("int","Interrupt",{
    {GTASM_ALLNUM},
},function(entity,arg)
    local id = arg[1]["convert"] or tonumber(arg[1]["data"])

    gTASM:SysInterrupt(entity,id)
end)

gTASM:NewOper("push","memory",{
    {GTASM_ALL},
},function(entity,arg)
    local var
    if arg[1]["n_type"] < GTASM_ALLMEM then
        if arg[1]["n_type"] == GTASM_STR then

        else
            var = arg[1]["convert"] or arg[1]["data"]
        end
    else
        local fromaddr,db = gTASM:GetAddresMem(entity,arg[1])
        if db then
            var = fromaddr
        else
            var = tonumber(entity.BANK:ReadS(fromaddr,1),2)
        end
    end

    
    local serv_start,serv_end = entity.BANK:GetBoardBlock("STACK")
    local stack_stat = tonumber(entity.BANK:ReadS(entity.regLabel.SP,1),2)
    entity.BANK:WriteS(serv_start + stack_stat, to8int(var))
    entity.BANK:WriteS(entity.regLabel.SP, to8int(stack_stat + 1))
end)

gTASM:NewOper("pop","memory",{
    {GTASM_VAR, GTASM_REG, GTASM_ADDR},
},function(entity,arg)
    local toaddr = gTASM:GetAddresMem(entity,arg[1])

    local serv_start,serv_end = entity.BANK:GetBoardBlock("STACK")
    local stack_stat = tonumber(entity.BANK:ReadS(entity.regLabel.SP,1),2)

    if stack_stat != 0 then
        stack_stat = stack_stat - 1
    end

    local var = tonumber(entity.BANK:ReadS(serv_start + stack_stat,1),2)

    entity.BANK:WriteS(toaddr,to8int(var))
    entity.BANK:WriteS(entity.regLabel.SP,to8int(stack_stat))
    entity.BANK:WriteS(serv_start+stack_stat,to8int(0))
end)

gTASM:NewOper("call","Procces",{
    {GTASM_STR},
},function(entity,arg)
    local label = arg[1]["data"][1]["data"]
    if entity.jumpLabel[label] then
        entity.BANK:WriteS(entity.regLabel.CR,to8int(entity.str_i))
        entity.str_i = entity.jumpLabel[label]
        --print("JUMP TO "..label)
    else
        --error
    end
end)

gTASM:NewOper("ret","Procces",{
    {GTASM_NOARG},
},function(entity,arg)
    local str_i = tonumber(entity.BANK:ReadS(entity.regLabel.CR),2)
    if str_i != 0 then
    entity.str_i = str_i
    --print("JUMP TO "..str_i)
    end

end)
