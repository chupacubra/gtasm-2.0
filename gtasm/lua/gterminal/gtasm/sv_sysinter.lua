gTASM = gTASM or {}

--[[
    1- stop script
    2- clear screen
    3- print the string
    4- fill the character
    5- fill the string
    6- print the string, arg only number end $
    7- ON the input keyboard arg is num max len and adress (for db), INP -> 1 (if the ply write INP -> 0)
    8- ON the input keytype, INK -> 1, INS -> 1, INS <- keynum
    9- file the string, arg addres,x,y "$"
    10- return random value   min,max if max == 0 then max = 255
    ...
    TODO
    ???- work with files
    ???- BLOCK :tasm stop  (for secure or viruses!!121)
    ???- ...
]]--
gTASM.InterList = {
    function(entity,arg)
        if !entity then
            return {0,1}
        end
        gTASM:ErrorScript(entity, GT_E_STOP, {NO_ARG = 0})
    end,

    function(entity,arg)
        if !entity then
            return 0
        end
        for i = 0, 25 do
            gTerminal:Broadcast(entity, "", MSG_COL_NIL, i);
        end;
    end,

    function(entity,arg)
        if !entity then
            return {0,15}
        end
        local text = RestoreString(arg)
        gTerminal:Broadcast(entity, text, GT_COL_SUCC)
    end,
    
    function(entity,arg)
        if !entity then
            return {0,2}
        end
        
        local x = tonumber(arg[1],2)
        local y = tonumber(arg[2],2)
        local char = string.char(tonumber(arg[3],2))

        gTASM:FillBroadcast(entity, char, GT_COL_MSG, y, x)
    end,

    function(entity,arg)
        if !entity then
            return {0,18}
        end
        
        local x = tonumber(arg[1],2)
        local y = tonumber(arg[2],2)
        table.remove(arg,1)
        table.remove(arg,1)

        local str = RestoreString(arg)

        gTASM:FillBroadcast(entity, str, GT_COL_MSG, y, x)
    end,

    function(entity,arg)
        if !entity then
            return {0,1}
        end
        
        local adres = tonumber(arg[1]..arg[2],2)

        local str = {}
        local char = entity.BANK:ReadS(adres,1)

        while tonumber(char, 2) != 36 and tonumber(char, 2) != 0 do -- 36 -> "$"
            table.insert(str,char)
            adres = adres + 1
            char = entity.BANK:ReadS(adres, 1)
        end

        gTerminal:Broadcast(entity,RestoreString(str))
    end,

    function(entity,arg)
        if !entity then
            return {0,1}
        end

        local max_len = tonumber(arg[1],2)
        local adress  = tonumber(arg[2],2)

        if !entity.FLAGS.inp then
            entity.FLAGS.inp = true
            entity.BANK:WriteS(entity.regLabel.INP,to8int(1))
            gTerminal:GetInput(entity, function(ply, arg)
                local str = string.Left(table.concat(arg), max_len)
                local var = ConvertString(str)

                for k,v in pairs(var) do
                    entity.BANK:WriteS(adress,to8int(v))
                    adress = adress + 1
                end
                entity.FLAGS.inp = false
                entity.BANK:WriteS(entity.regLabel.INP,to8int(0))
            end)

        end
    end,

    function(entity,arg)
        if !entity then
            return 0
        end

        if !entity.FLAGS.ink then
            entity.FLAGS.ink = true
            
            gTerminal:StartKeyType(entity,entity:GetUser())
            entity.BANK:WriteS(entity.regLabel.INK,to8int(1))
        end
    end,

    function(entity,arg)
        if !entity then
            return {0,3}
        end
        local adres = tonumber(arg[1]..arg[2],2)
        local x = tonumber(arg[3],2)
        local y = tonumber(arg[4],2)

        local str = {}
        local char = entity.BANK:ReadS(adres,1)

        while tonumber(char, 2) != 36 and tonumber(char, 2) != 0 do -- 36 -> "$"
            table.insert(str,char)
            adres = adres + 1
            char = entity.BANK:ReadS(adres, 1) 
        end

        gTASM:FillBroadcast(entity,RestoreString(str), GT_COL_MSG,y,x)
    end,

    function(entity,arg)
        if !entity then
            return {0,1}
        end
        local min,max = tonumber(arg[1],2),tonumber(arg[2],2)
        if max == 0 then
            max = 255
        end
        local num = math.random(min,max)

        entity.BANK:WriteS(entity.BANK:GetBoardBlock("SERVICE"),to8int(num))
    end,

    function(entity,arg)
        if !entity then
            return {0,1}
        end

        local b = entity.BANK:GetBlock(tonumber(arg[1],2))

        if b == false then
            gTerminal:Broadcast(entity,"--MEMORY DUMP--",GT_COL_SUCC)
            gTerminal:Broadcast(entity,"UNABLE TO CREATE MEMORY DUMP")
            return
        end

        local dig = b.block.data[tonumber(arg[2],2)]
        if dig == nil then
            gTerminal:Broadcast(entity,"--MEMORY DUMP--",GT_COL_SUCC)
            gTerminal:Broadcast(entity,"UNABLE TO CREATE MEMORY DUMP")
            return
        end

        local block_tbl = strMemBlock(tobase(dig,2,64),40)
        gTerminal:Broadcast(entity,"--MEMORY DUMP--",GT_COL_SUCC)
        for k,v in pairs(block_tbl) do
            gTerminal:Broadcast(entity, table.concat(v),GT_COL_SUCC)
        end

    end,

    function(entity,arg)
        if !entity then
            return {0,1}
        end

        local b = entity.BANK:GetBlock(tonumber(arg[1],2))
        if b == false then
            gTerminal:Broadcast(entity,"--MEMORY DUMP--",GT_COL_SUCC)
            gTerminal:Broadcast(entity,"UNABLE TO CREATE MEMORY DUMP")
            return
        end

        local digits = b.block.data
        local part   = tonumber(arg[2],2)

        local max_parts = math.ceil(b.block.dcount / 12)

        if part < 1 or (max_parts < part) or digits == nil then
            gTerminal:Broadcast(entity,"--MEMORY DUMP--",GT_COL_SUCC)
            gTerminal:Broadcast(entity,"UNABLE TO CREATE MEMORY DUMP")
            return
        end

        local i_start = ((part - 1) * 12)+1
        local i_end

        if b.block.dcount <= 12 then
            i_end   = b.block.dcount
        else
            local m = 0
            
            if (part * 12) > b.block.dcount then
                m = (part * 12) - b.block.dcount
            end

            i_end   = (part * 12) - m
        end
        
        local allstring = {}
        local formtString = {}

        for k=i_start,i_end do
            local block_tbl = strMemBlock(tobase(digits[k],2,64),40)

            for kk,vv in pairs(block_tbl) do
                if formtString[kk] == nil then 
                    formtString[kk] = table.concat(vv)
                else
                    formtString[kk] = formtString[kk] .. " " .. table.concat(vv)
                end
            end
            
            if k % 3 == 0 then
                table.insert(allstring,formtString)
                formtString = {}
            end
        end

        if #formtString > 0 then
            table.insert(allstring,formtString)
            formtString = {}
        end
        
        gTerminal:Broadcast(entity, "MEMORY DUMP PREPARING", GT_COL_SUCC)
        gTerminal:Broadcast(entity, "ID = ".. b.id, GT_COL_SUCC)
        gTerminal:Broadcast(entity, "BLOCKS = ".. b.block.dcount,GT_COL_SUCC)
        gTerminal:Broadcast(entity, "PART = "..part.."/"..max_parts,GT_COL_SUCC)

        timer.Simple(1, function()
            --[[
            for i = 0, 25 do
                gTerminal:Broadcast(entity, "", MSG_COL_NIL, i);
            end
            --]]

            for k,v in pairs(allstring) do
                for kk,vv in pairs(v) do
                    gTerminal:Broadcast(entity,vv,GT_COL_SUCC)

                end
                gTerminal:Broadcast(entity,"",GT_COL_SUCC)
            end

        end)
--[[
        gTASM:FillBroadcast(entity, "MEMORY DUMP", GT_COL_SUCC, 19, 34)
        gTASM:FillBroadcast(entity, "ID = ".. b.id, GT_COL_SUCC, 21, 32)
        gTASM:FillBroadcast(entity, "BLOCKS = ".. b.block.dcount,GT_COL_SUCC,22,32)
        gTASM:FillBroadcast(entity, "PART = "..part.."/"..max_parts,GT_COL_SUCC,23,32)
--]]
    end
}

function gTASM:SysInterrupt(entity,id)
    local serv = entity.BANK:GetBoardBlock("SERVICE")

    if !self.InterList[id] then
        gTASM:ErrorScript(entity, GT_E_INT_UNK, {ID_INT = tostring(id)})
        return
    end

    local mem = self.InterList[id]()
    
    if mem == 0 then
        self.InterList[id](entity)
    else
        local arg = {}
        for i = mem[1], mem[2] do
            table.insert(arg,entity.BANK:ReadS(serv + i,1,true))
        end
        self.InterList[id](entity,arg)
    end
end
MsgC(Color(0, 255, 0), "Initialized gTASM commands!\n");