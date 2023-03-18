function ConvertString(str)  
    local function comp(...)
        return {...}
    end

    local rez = comp(string.byte(str, 1,string.len(str)))
    return rez
end

function splitByChunk(text, chunkSize)
    local s = {}
    for i=1, #text, chunkSize do
        s[#s+1] = text:sub(i,i+chunkSize - 1)
    end
    return s
end

function ISDB(entity,name)
    if entity.dbLabel.dbList[name] then
        return true
    end
    return false
end

function to8int(vall)
    local val = tonumber(vall)
	while val > 255 do
		val = val - 256
	end
	while val < 0 do
		val = val + 256
	end

    return tobase(tonumber(val),2,8)
end

function strtonum(str) 
    if string.len(str) == 0 then return 0 end

    local arr = string.ToTable(str)
    local fin = {}
    for k,v in pairs(arr) do
        local ch = string.byte(arr[k])
        local a = to8int(ch)
        for i=1,8 do
            table.insert(fin,a[i])
        end
    end

    return fin
end

function strtobyte(str) 
    if string.len(str) == 0 then return 0 end

    local arr = string.ToTable(str)
    local fin = {}
    for k,v in pairs(arr) do
        local ch = string.byte(arr[k])
        table.insert(fin,ch)
    end

    return fin
end

function strtonum16(str) 
    if string.len(str) == 0 then return 0 end

    local arr = string.ToTable(str)

    for k,v in pairs(arr) do
        local ch = string.byte(arr[k])
        local bn  = table.concat(tobinval(ch,2))
        arr[k] = bn
    end
    
    return table.concat(arr)
end

function haveComment(arr)
	for k,v in pairs(arr) do
	  if v == "#" and arr[k-1] != "%" then return true end
	end
	return false
end

function RestoreString(val)
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

function tobinval(val, size,for8bit)
    if size == nil then
        size = 1
    end
    
    while val > 2^(size*8) do 
		val = val - 2^(size * 8)
	end

	while val < 0 do
		val = val + 2^(size * 8)
	end

    if for8bit then
        local var = tobase(tonumber(val),2,8 * size)
        local i = 0
        local rez = {{}} 
        
        for k,v in pairs(var) do
            table.insert(rez[#rez], v)
            i = i + 1
            if i == 8 then
                rez[#rez+1] = {}
                i = 0
            end
        end
        return rez 
    end
    return tobase(tonumber(val),2,8 * size)
end

function getbv(val)
    local s = 8
    while val > 2 ^ s do
        s = s + 8
    end

    return s / 8 
end

function bin_not(val)
    for i=1,#val do
        if val[i] == 1 then
            val[i] = 0
        else
            val[i] = 1
        end
    end
    return val
end