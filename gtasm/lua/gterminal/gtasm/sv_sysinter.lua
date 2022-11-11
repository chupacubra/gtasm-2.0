gTASM = gTASM or {}
--[[
local function RestoreString(val)
    local str = ""
    for k,v in pairs(val) do
        if tonumber(v,2) > 32 then
            str = str .. string.char(tonumber(v,2))
        else
            str = str .. " "
        end
    end
    return str
end

local function ConvertString(str)
    local function comp(...)
        return {...}
    end

    local rez = comp(string.byte(str, 1,string.len(str)))
    return rez
end
--]]
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
    ???- get input
    ???- work with files
    ???- 2 type of keyboard input(for games or text redactors)
    ???- BLOCK :tasm stop  (for secure or viruses!!121)
    ???- ...
]]--
gTASM.InterList = {
    function(ent,arg)
        if !ent then
            return 0
        end
        gTerminal:EndScript(entity)
    end,

    function(ent,arg)
        if !ent then
            return 0
        end
        for i = 0, 25 do
            gTerminal:Broadcast(ent, "", MSG_COL_NIL, i);
        end;
    end,

    function(ent,arg)
        if !ent then
            return {0,15}
        end
        local text = RestoreString(arg)
        gTerminal:Broadcast(ent,text,GT_COL_SUCC)
    end,
    
    function(ent,arg)
        if !ent then
            return {0,2}
        end
        
        local x = tonumber(arg[1],2)
        local y = tonumber(arg[2],2)
        local char = string.char(tonumber(arg[3],2))

        gTerminal:Broadcast(ent, char, GT_COL_MSG, y, x)
    end,

    function(ent,arg)
        if !ent then
            return {0,18}
        end
        
        local x = tonumber(arg[1],2)
        local y = tonumber(arg[2],2)
        table.remove(arg,1)
        table.remove(arg,1)

        local str = RestoreString(arg)

        gTerminal:Broadcast(ent, str, GT_COL_MSG, y, x)
    end,

    function(ent,arg)
        if !ent then
            return {0,1}
        end
        --print("print the str")
        local adres = tonumber(arg[1],2)

        local str = {}
        local char = ent.BANK:ReadS(adres,1)
        while string.char(tonumber(char,2)) != "$" or tonumber(char,2) == 0 do
            table.insert(str,char)
            adres = adres + 1
            char = ent.BANK:ReadS(adres,1)
        end
        gTerminal:Broadcast(ent,RestoreString(str))
    end,

    function(ent,arg)
        if !ent then
            return {0,1}
        end

        local max_len = tonumber(arg[1],2)
        local adress  = tonumber(arg[2],2)

        if !ent.FLAGS.inp then
            ent.FLAGS.inp = true
            ent.BANK:WriteS(ent.regLabel.INP,to8int(1))
            gTerminal:GetInput(ent, function(ply, arg)
                local str = string.Left(table.concat(arg), max_len)
                local var = ConvertString(str)

                for k,v in pairs(var) do
                    ent.BANK:WriteS(adress,to8int(v))
                    adress = adress + 1
                end
                ent.FLAGS.inp = false
                ent.BANK:WriteS(ent.regLabel.INP,to8int(0))
            end)

        end
    end,

    function(ent,arg)
        if !ent then
            return 0
        end

        if !ent.FLAGS.ink then
            ent.FLAGS.ink = true
            
            gTerminal:StartKeyType(ent,ent:GetUser())
            ent.BANK:WriteS(ent.regLabel.INK,to8int(1))
        end
    end,

    function(ent,arg)
        if !ent then
            return {0,2}
        end
        --print("print the str")
        local adres = tonumber(arg[1],2)
        local x = tonumber(arg[2],2)
        local y = tonumber(arg[3],2)
        
        local str = {}
        local char = ent.BANK:ReadS(adres,1)
        while string.char(tonumber(char,2)) != "$" or tonumber(char,2) == 0 do
            table.insert(str,char)
            adres = adres + 1
            char = ent.BANK:ReadS(adres,1)
        end
        gTerminal:Broadcast(ent,RestoreString(str), GT_COL_MSG,x,y)
    end,

    function(ent,arg)
        if !ent then
            return {0,1}
        end
        local min,max = tonumber(arg[1],2),tonumber(arg[2],2)
        if max == 0 then
            max = 255
        end
        local num = math.random(min,max)
        print(min,max,num)
        ent.BANK:WriteS(ent.BANK:GetBoardBlock("SERVICE"),to8int(num))
    end,
}

function gTASM:SysInterrupt(entity,id)
    local serv = entity.BANK:GetBoardBlock("SERVICE")

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