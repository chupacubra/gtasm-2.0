gTASM = gTASM or {}

local function haveComment(arr)
	for k,v in pairs(arr) do
	  if v == "#" and arr[k-1] != "%" then return true end
	end
	return false
  end
  
function gTASM:SetUpMemory(entity)
	entity.BANK = BankMem:Create({
		{"REGISTR",320}, 
		{"STACK",320},   
		{"POOL1",320},   
		{"POOL2",320},  
		{"SERVICE",320},
		{"GLOBAL",320},
	})
	entity.memLabel = {}
	entity.jumpLabel = {}
	entity.endscr = false
	entity.regLabel = {
		R1 = 0,R2 = 2,R3 = 4,
		R4 = 6,R5 = 8,R6 = 10,
		R7 = 12,R8 = 14,

		IP = 31,
		SP = 32,
		CF = 33,
		ZF = 34,
		CR = 35,
		INP = 36,
		INK = 37,
		INS = 38,
	}

	entity.FLAGS = {
		cf = false,
		zf = false,
		inp = false,
		ink = false,
	}

	entity.dbLabel = {
		endPos = entity.BANK:GetBoardBlock("POOL1"),
		dbList = {}
	}
end

function gTASM:PreparTheScript(code)
    local ccode = {}
    
	for k,v in pairs(code) do 
		local str = string.Trim(v)

		if str != "" and str != "\n" then
			ccode[#ccode + 1] = str
		end
	end
	
	local code = ccode
	ccode = nil 

	for k,v in pairs(code) do
		if string.find(v,"#") then
			local tbc = string.toTable(v)
			local posp = {}
			local srt
			local find = false
			for kk,vv in pairs(tbc) do
				if find == false then
					if vv == "#" and tbc[kk-1] != "%" then
						srt = table.concat(tbc,"")
						srt = string.Left(srt,kk-1)
						find = true
					end
				end 
			end
			local str
			if srt then
				str = string.gsub(srt,"%%%#","#")
			else
				str = string.gsub(table.concat(tbc),"%%%#","#")
			end
			code[k] = string.Trim(str)
		end
	end

    local function AddStrArr(arr,nextstr,i)
        if string.EndsWith( nextstr, ">;" ) then
            nextt =  string.reverse(string.gsub(string.reverse(v), ";>", "", 1))
            table.insert(arr,nextt)
            return AddStrArr(arr,code[i+1],i+1)
        else
            table.insert(arr,nextstr)
            return arr
        end
    end

	for k,v in pairs(code) do -- get the next str and add 
		if string.EndsWith( v, ">;" ) then 
			local start_str = v
			local start_k   = k

			local finstr = AddStrArr({},v,k)
			local str    = table.concat(finstr)
			code[start_k] = str

			for i=2, #finstr do
				table.remove(code,start_k+1)
			end
			v = str
		end
	end

    return code 
end
