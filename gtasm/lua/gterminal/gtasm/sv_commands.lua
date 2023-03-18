include("sv_sysinter.lua")
gTASM = gTASM or {}

function gTASM:ToVar(entity,argum)
    local var_list = {}

    for k,v in pairs(argum) do
        local fin = {}
        if k == "label" then
            var_list.label = v
            continue
        end

        if v.n_type < GTASM_ALLMEM then
            table.insert(var_list,v)

        elseif v.n_type == GTASM_STR then
            table.insert(var_list,v)

        elseif v.n_type > GTASM_ALLMEM then
            local addr,db = gTASM:GetAddresMem(entity,v)
            local var = 0

            if db then
                var = addr
            else
                var = tonumber(entity.BANK:ReadS(addr,v.byte_size or 1), 2)
            end

            fin.data = var
            fin.mem_addres = addr
            fin.n_type = v.n_type
            fin.byte_size = v.byte_size

            table.insert(var_list, fin)
        end
    end

    return var_list
end

function gTASM:GetAddresMem(ent,arg)

    if arg.n_type == GTASM_REG then
        if ent.regLabel[arg.data] then
            return ent.regLabel[arg.data]
        elseif arg.mem_addres then
            return arg.mem_addres
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

            local addresbyte = arg.byte_size
            local argbyte = 1
            if arg.data[1]["byte_size"] != nil then
                argbyte = arg.data[1]["byte_size"]
            end
            
            local isdb = ISDB(ent,arg.data[1]["data"])
            local rez

            if isdb then
                rez = addr
            else
                rez = tonumber(ent.BANK:ReadS(addr,argbyte or 1),2)
            end

            return rez,isdb
        end
    end

end

function gTASM:ExecuteCommand(ent, cmd)
    if cmd.oper == nil then
        return
    end
    local name = string.lower(cmd.oper)
    local arg  = cmd.arg

    if self.cmds[name] == nil then
        return  4,{CMD_E = name}
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
            if v.n_type == "string" and allowtype.no_string then
                return 6,{ARG_ID = k}
            end

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

    local table_arg = gTASM:ToVar(ent, arg)
    local result = self.cmds[name]["func"](ent,table_arg)
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
    local addr = arg[1]["mem_addres"]
    local value = arg[2]["convert"] or arg[2]["data"]

    entity.BANK:WriteS(addr, tobinval(value, arg[2]["byte_size"]))
end)

gTASM:NewOper("add","Memory",{
    {GTASM_VAR, GTASM_REG, GTASM_ADDR},
    {GTASM_ALL}
},function(entity,arg)
    local addr = arg[1]["mem_addres"]
    local val1 = arg[1]["convert"] or arg[1]["data"]
    local val2 = arg[2]["convert"] or arg[2]["data"]

    local val = val1 + val2
    local byte_size = arg[2]["byte_size"] or 1
    if val > 2 ^ (8 * byte_size) then
        gTASM:SetRegister(entity,"CF",1)
    else
        gTASM:SetRegister(entity,"CF",0)
    end

    entity.BANK:WriteS(addr, tobinval(val, byte_size))
end)

gTASM:NewOper("sub","Memory",{
    {GTASM_VAR, GTASM_REG, GTASM_ADDR},
    {GTASM_ALL}
},function(entity,arg)
    local addr = arg[1]["mem_addres"]
    local val1 = arg[1]["convert"] or arg[1]["data"]
    local val2 = arg[2]["convert"] or arg[2]["data"]

    local val = val1 - val2

    if val < 0 then
        gTASM:SetRegister(entity, "CF",1)
    else
        gTASM:SetRegister(entity, "CF",0)
    end

    entity.BANK:WriteS(addr, tobinval(val, arg[1]["byte_size"]))
end)

gTASM:NewOper("sbb","Memory",{
    {GTASM_VAR, GTASM_REG, GTASM_ADDR},
    {GTASM_ALL}
},function(entity,arg)
    local addr = arg[1]["mem_addres"]
    local val1 = arg[1]["convert"] or arg[1]["data"]
    local val2 = arg[2]["convert"] or arg[2]["data"]
    local cf =  gTASM:GetRegister(entity, "CF")

    local val = val1 - val2 - cf

    if val < 0 then
        gTASM:SetRegister(entity, "CF",1)
    else
        gTASM:SetRegister(entity, "CF",0)
    end

    entity.BANK:WriteS(addr, tobinval(val,arg[1]["byte_size"]))
end)

gTASM:NewOper("adc","Math",{
    {GTASM_VAR, GTASM_REG, GTASM_ADDR},
    {GTASM_ALL},
    no_string = true

},function(entity,arg)
    local addr = arg[1]["mem_addres"]
    local var1 = arg[1]["convert"] or arg[1]["data"]
    local var2 = arg[2]["convert"] or arg[2]["data"]
    local cf =  gTASM:GetRegister(entity, "CF")

    local val = var1 + var2 + cf
    local byte_size = arg[1]["byte_size"] or 1

    if val > 2 ^ (8 * byte_size) then
        gTASM:SetRegister(entity, "CF",1)
    else
        gTASM:SetRegister(entity, "CF",0)
    end

    entity.BANK:WriteS(addr, tobinval(val, arg[1]["byte_size"]))
end)


gTASM:NewOper("and","Math",{
    {GTASM_VAR, GTASM_REG, GTASM_ADDR},
    {GTASM_ALL}
},function(entity,arg)
    local addr = arg[1]["mem_addres"]
    local var1 = arg[1]["data"]
    local var2 = arg[2]["data"] or arg[2]["convert"]

    entity.BANK:WriteS(addr, tobinval(bit.band(var2 , var1), arg[1]["byte_size"]))
end)

gTASM:NewOper("or","Math",{
    {GTASM_VAR, GTASM_REG, GTASM_ADDR},
    {GTASM_ALL}
},function(entity,arg)
    local addr = arg[1]["mem_addres"]
    local var1 = arg[1]["data"]
    local var2 = arg[2]["data"] or arg[2]["convert"]

    entity.BANK:WriteS(addr, tobinval(bit.bor(var2 , var1), arg[1]["byte_size"]))
end)

gTASM:NewOper("xor","Math",{
    {GTASM_VAR, GTASM_REG, GTASM_ADDR},
    {GTASM_ALL}
},function(entity,arg)
    local addr = arg[1]["mem_addres"]
    local var1 = arg[1]["data"]
    local var2 = arg[2]["data"] or arg[2]["convert"]

    entity.BANK:WriteS(addr, tobinval(bit.bxor(var2 , var1), arg[1]["byte_size"]))
end)


gTASM:NewOper("not","Math",{
    {GTASM_VAR, GTASM_REG, GTASM_ADDR}
},function(entity,arg)
    local addr = arg[1]["mem_addres"]
    local var  = arg[1]["data"]

    entity.BANK:WriteS(addr,bin_not(tobinval(var, arg[1]["byte_size"])))
end)

gTASM:NewOper("inc","Memory",{
    {GTASM_VAR, GTASM_REG, GTASM_ADDR},
    {GTASM_ALL}
},function(entity,arg)
    local addr = arg[1]["mem_addres"]
    local val1 = arg[1]["convert"] or arg[1]["data"]

    local val = val1 + 1
    local byte_size = arg[1]["byte_size"] or 1

    if val > 2 ^ (8 * byte_size) then
        gTASM:SetRegister(entity,"CF",1)
    else
        gTASM:SetRegister(entity,"CF",0)
    end

    entity.BANK:WriteS(addr, tobinval(val,arg[1]["byte_size"]))
end)

gTASM:NewOper("dec","Memory",{
    {GTASM_VAR, GTASM_REG, GTASM_ADDR},
    {GTASM_ALL}
},function(entity,arg)
    local addr = arg[1]["mem_addres"]
    local val1 = arg[1]["convert"] or arg[1]["data"]

    local val = val1 - 1
    local byte_size = arg[1]["byte_size"] or 1
    if val > 2 ^ (8 * byte_size) then
        gTASM:SetRegister(entity,"CF",1)
    else
        gTASM:SetRegister(entity,"CF",0)
    end

    entity.BANK:WriteS(addr, tobinval(val,arg[1]["byte_size"]))
end)

gTASM:NewOper("cmp","Logic",{
    {GTASM_ALL},
    {GTASM_ALL}
},function(entity,arg)
    local addr = arg[1]["mem_addres"]
    local var1 = arg[1]["data"]
    local var2 = arg[2]["convert"] or arg[2]["data"]


    var1 = var1 - var2
    
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
    gTASM:SetRegister(entity,"CF",cf)
    gTASM:SetRegister(entity,"ZF",zf)
end)

gTASM:NewOper("db","Memory",{
    {GTASM_ALL},
    size_nolimit = true
},function(entity,arg)

    local rez = {}
    local labl

    if arg.label then
        labl = arg.label
        arg.label = nil
    end

    for k,v in pairs(arg) do
        if v.n_type == GTASM_STR then
            local str = ConvertString(v.data)
            
            for k,v in pairs(str) do
                table.insert(rez,to8int(v))
            end
        else
            local data = v.convert or v.data

            local bdat = tobinval(data,v.byte_size, true)

            for k,v in pairs(bdat) do
                table.insert(rez,v)
            end
        end
    end

    gTASM:InsertDBInMemory(entity,rez,labl)
end)

gTASM:NewOper("jmp","Logic",{
    {GTASM_STR},
},function(entity,arg)
    local label = arg[1]["data"]
    if entity.jumpLabel[label] then
        entity.str_i = entity.jumpLabel[label]
    end
end)

gTASM:NewOper("je","Logic",{
    {GTASM_STR},
},function(entity,arg)
    local label = arg[1]["data"]

    if entity.jumpLabel[label] then
        local zf = gTASM:GetRegister(entity,"ZF")
        if tonumber(zf,2) == 1 then
            entity.str_i = entity.jumpLabel[label]
        end
    end
end)

gTASM:NewOper("jne","Logic",{
    {GTASM_STR},
},function(entity,arg)
    local label = arg[1]["data"][1]

    if entity.jumpLabel[label] then
        local zf = gTASM:GetRegister(entity,"ZF")
        if tonumber(zf,2) == 0 then
            entity.str_i = entity.jumpLabel[label]
        end
    end
end)

gTASM:NewOper("jb","Logic",{
    {GTASM_STR},
},function(entity,arg)
    local label = arg[1]["data"]
    if entity.jumpLabel[label] then
        local cf = gTASM:GetRegister(entity,"CF")

        if tonumber(cf,2) == 1 then
            entity.str_i = entity.jumpLabel[label]
        end
    end
end)

gTASM:NewOper("ja","Logic",{
    {GTASM_STR},
},function(entity,arg)
    local label = arg[1]["data"]
    if entity.jumpLabel[label] then
        local cf = tonumber(gTASM:GetRegister(entity,"CF"),2)
        local zf = tonumber(gTASM:GetRegister(entity,"ZF"),2)

        if cf == 0  and zf == 0 then
            entity.str_i = entity.jumpLabel[label]
        end
    end
end)

gTASM:NewOper("int","Interrupt",{
    {GTASM_ALLNUM},
},function(entity,arg)
    local id = arg[1]["convert"] or arg[1]["data"]

    gTASM:SysInterrupt(entity,id)
end)


gTASM:NewOper("push","memory",{
    {GTASM_ALL},
},function(entity,arg)
    local var = arg[1]["data"]

    gTASM:StackPush(entity, var, arg[1]["byte_size"] or 1)
end)

gTASM:NewOper("pop","memory",{
    {GTASM_VAR, GTASM_REG, GTASM_ADDR},
},function(entity,arg)
    local addr = arg[1]["mem_addres"]
    local var = gTASM:StackPop(entity, arg[1]["byte_size"])

    entity.BANK:WriteS(toaddr, tobinval(var,arg[1]["byte_size"]))
end)

gTASM:NewOper("call","Procces",{
    {GTASM_STR},
},function(entity,arg)
    local label = arg[1]["data"]
    if entity.jumpLabel[label] then
        gTASM:StackPush(entity, entity.str_i, 2)
        entity.str_i = entity.jumpLabel[label]
    end
end)

gTASM:NewOper("ret","Procces",{
    {GTASM_ALLNUM},
},function(entity,arg)
    --local label = arg[1]["data"]  arg[1]["convert"] or arg[1]["data"]
    local i = gTASM:StackPop(entity,2)
    print("FROM stack",i)
    entity.str_i = i
end)