function ConvertString(str)  
    local function comp(...)
        return {...}
    end

    local rez = comp(string.byte(str, 1,string.len(str)))
    return rez
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
		val = val - 255
	end
	while val < 0 do
		val = val + 255
	end
    return tobase(tonumber(val),2,8)
end

function strtonum(str)
    if string.len(str) == 0 then return 0 end

    local arr = string.ToTable(str)

    for k,v in pairs(arr) do
        local ch = string.byte(arr[k])
        local bn  = table.concat(to8int(ch))
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

  