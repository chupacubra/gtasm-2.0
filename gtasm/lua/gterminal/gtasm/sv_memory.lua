BlockMem = {}
BankMem  = {}


local arrhex = {
    0,0,0,0,0,0,0,0,0,
    "A",
    "B",
    "C",
    "D",
    "E",
    "F",
}

local zero = "00000000"
function hval(hex)
    local str = ""
    for k,v in pairs(hex) do
        if v < 10 then
            str = str .. v
        else
            str = str .. arrhex[v]
        end
    end
    return str
end

pt = function(t)
    for k,v in pairs(t) do
         print(k,v)
    end
end 

function printMemBlock(arr,len)
    local llen = len / 16
    print("BLOCK")
    local ii = 0
    local str = ""
    local hp = {}
    local str_i = 0
    for i = 1,len do
        str = str .. arr[i]
        table.insert(hp,arr[i])
        ii = ii + 1
        if ii == 8 then
            local tbl = tobase(digitsToNum(hp,2),16)
            local hex = hval(tbl)
            print(str_i .." = "..str, hex)
            hp = {}
            ii = 0
            str_i = str_i + 1
            str = ""
        end
    end
end

function strMemBlock(arr,len)
    local llen = len / 16
    local ii = 0
    local str = ""
    local hp = {}
    local str_i = 0
    local str_arr = {}
    for i = 1,len do
        str = str .. arr[i]
        table.insert(hp,arr[i])
        ii = ii + 1
        if ii == 8 then
            local tbl = tobase(digitsToNum(hp,2),16)
            local hex = hval(tbl)
            
            if string.len(hex) < 2 then
                if string.len(hex) == 1 then
                    hex = hex .." "
                elseif string.len(hex) == 0 then
                    hex = hex .."  "
                end
            end
            
            table.insert(str_arr,{str_i .." = "..str.."  "..hex})
            hp = {}
            ii = 0
            str_i = str_i + 1
            str = ""
        end
    end
    return str_arr
end

tlen = function(table)
   local count = 0
    for _,_ in pairs(table) do
        count = count + 1
    end
    return count
end

digitsToNum = function(digits, base)
    local num, k = 0, 1
    for i = #digits, 1, -1 do
        if digits[i] >= base then
            error("\number transfromation error: could not transfrom number "
            ..tostring(digits[i]).." to base "..tostring(base))
        end
        num = num + digits[i] * k
        k = k * base
    end
    return num
end

getNumberLength = function(num, base)
        if num == 0 then return 0 end
        if num < 0 then num = -num end
        return math.floor(math.log(num) / math.log(base)) + 1
    end

tobase = function(num, base, forcedLength)
    local length, t = getNumberLength(num, base), {}
    if forcedLength ~= nil then
        for i = 1, forcedLength do t[i] = 0 end
    end
    local l = math.max(forcedLength or 0, length)
    for i = 1, length do
        local v = num % base
        t[l - i + 1] = v
        num = math.floor(num / base)
    end
    
    if forcedLength != nil and forcedLength < #t then
        while forcedLength != #t do
            table.remove(t,1)
        end
    end

    return t
end


function BlockMem:New(size)
    local obj = {}
    obj.data  = {}
    obj.dcount = size / 40
    obj.bsize  = size / 8

    for i = 1, obj.dcount do
        table.insert(obj.data,0)
    end

    function obj:SegPos(pos)
        local idd = math.floor(pos / 5) + 1
        local lpos = pos
        while pos >= 5 do
            pos = pos - 5
            if pos == 5 then
                pos = 0
                break
            end
        end
        if idd == 0 then idd = 1 end

        return idd,(pos * 8)
    end

    function obj:ReadS(pos, byte)
        local dgt,dpos = self:SegPos(pos)

        if dpos >= 40 then
            dpos = dpos - 40
            dgt = dgt + 1
        end

        local data = self.data[dgt]
        local arr = tobase(data, 2, 64)
        local rez = {}

        local shift = 1
        local writeshift = 1

        while table.Count(rez) != 8*(byte or 1) do
            if dpos+shift > 40 then
                dgt = dgt + 1
                if !self.data[dgt] then
                    -- error
                    return "00000000"
                end
                arr = tobase(self.data[dgt],2,64)
                dpos =  0
                shift = 1
            end
            rez[writeshift] = arr[dpos + shift]
            
            writeshift = writeshift + 1
            shift = shift + 1
        end

        return table.concat(rez),byte or nil
    end

    function obj:WriteS(pos,val)
        local dgt,dpos = self:SegPos(pos)

        if dpos >= 40 then
            dpos = dpos - 40
            dgt = dgt + 1
        end

        local data = self.data[dgt]
        local arr = tobase(data,2,64)
        local arrm = {}

        for i = 1,#val do
            if dpos + i > 40 then
                if #self.data < dgt+1 then
                    return false
                end
                table.insert(arrm,{arr,dgt})
                arr = tobase(self.data[dgt + 1],2,64)
                dgt = dgt + 1
                dpos = 1 - i
            end
            arr[dpos + i] = val[i]
        end
        if #arrm > 0 then
            table.insert(arrm,{arr,dgt})

            for k,v in pairs(arrm) do
                self.data[v[2]] = digitsToNum(v[1],2)
            end
        else

            self.data[dgt] = digitsToNum(arr,2)
        end

    end

    function obj:PrintVal() -- for debug
        for k,v in pairs(self.data) do
            local arr = tobase(v,2,64)
            print("BLOCK: ",k)
            printMemBlock(arr,64)
            print("-------")
        end
    end

    setmetatable(obj, self)
    self.__index = self; return obj
end

function BankMem:Create(array, eid)
    local obj = {}
    obj.bdata = {}
    obj.bdsize = -1
    obj.eid = eid
    for k,v in pairs(array) do
        local size = v[2] / 8
        local bit_size = v[2]
        local name = v[1]

        table.insert(obj.bdata,{
            id = name,
            b_start = obj.bdsize + 1,
            b_end = obj.bdsize + size,
            b_size = size,
            block = BlockMem:New(bit_size),
        })
        obj.bdsize = obj.bdsize + size 
    end

    function obj:GetMax()
        return self.bdsize
    end

    function obj:InsertNew(array)
        for k,v in pairs(array) do
            local size = v[2] / 8
            local bit_size = v[2]
            local name = v[1]
    
            table.insert(obj.bdata,{
                id = name,
                b_start = obj.bdsize + 1,
                b_end = obj.bdsize + size,
                b_size = size,
                block = BlockMem:New(bit_size),
            })
            obj.bdsize = obj.bdsize + size 
        end
    end

    function obj:BlockPos(apos)
        local pos = tonumber(apos)

        if pos > self.bdsize then
            return -1
        end
        if pos < 0 then
            return -1
        end

        local posb      = pos
        local block_pos = 0
        local block_idp = 0

        for k,v in pairs(self.bdata) do
            if pos >= v.b_start then
                if pos <= v.b_end then
                    block_idp = k
                    break
                else
                    posb = posb - v.b_size
                end
            end
        end

        return block_idp,posb
    end

    function obj:ReadS(posa, byte)
        if posa == nil then
            return zero
        end
        local bpos,pos = self:BlockPos(posa)
        if bpos == -1 then
            self:ErrorM({posa,byte})
            return zero
        end
        local block = self.bdata[bpos]["block"]
        local dat = block:ReadS(pos,byte)
        
        if dat == false then
            self:ErrorM({posa,byte})
            return zero
        end
        
        return dat
    end

    function obj:WriteS(posa,val)
        local bpos,apos = self:BlockPos(posa)
        if bpos == -1 then
            self:ErrorM({posa,byte})
            return zero
        end
        local succes = self.bdata[bpos]["block"]:WriteS(apos,val)
        if succes == false then
            self:ErrorM({posa,byte})
        end
    end

    function obj:GetBlock(name)
        if type(name) == "string" then
            for k,v in pairs(self.bdata) do
                if v.id == name then
                    return v.block
                end
            end
        else
            return self.bdata[name] or false
        end
        return false
    end

    function obj:GetAllBLocks()
        return self.bdata,self.bdsize
    end
    
    function obj:GetSizeBlock(name)
        for k,v in pairs(self.bdata) do
            if v.id == name then
                return v.b_size
            end
        end
    end

    function obj:GetBoardBlock(name)
        for k,v in pairs(self.bdata) do
            if v.id == name then
                return v.b_start, v.b_end 
            end
        end
    end
    
    function obj:ErrorM(arg)
        --debug.Trace()
        hook.Call("gTASM","MemoryIndexE", self.eid,arg)
    end

    setmetatable(obj, self)
    self.__index = self; return obj
end