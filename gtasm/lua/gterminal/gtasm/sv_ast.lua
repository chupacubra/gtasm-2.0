include("sv_lexertasm.lua")

local function NumType(type,data)
	if type == "variable" then
		return GTASM_VAR
	elseif type == "ident" then
		return GTASM_REG
	elseif type == "number" then
		return GTASM_DNUM
	elseif type == "addres" then
		return GTASM_ADDR
	elseif type == "bin_val" then
		return GTASM_BNUM
	elseif type == "hex_val" then
		return GTASM_HNUM
	elseif type == "string" then
		return GTASM_STR
	else
		return -1
	end
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
        --if num < base then break end
        num = math.floor(num / base)
    end
    return t
end

function ConvertNum(data,type)
    local fdata = 0
    if type == "hex_val" then
        fdata = tonumber(data,16)
    else
        local data = string.gsub(data,"0b","",1)
        fdata = tonumber(data,2)
    end
    return fdata
end


function newast(lex)
    local pos = 0
    local tocken = {}
    local string_t = false 
    local addres_t = false
    local oper = false
    local label = false
    local ast = {}
    local comma = 1
    local cl_lex = {}
    local addres_a = {}
    ast.arg = {}
    ast.arg[comma] = {}

    local function get_tocken(s)
        local t = lex[pos + (s or 0)]

        return t or {type = "end_line",data=""}
    end

    local function nextop()
        pos = pos + 1
        return get_tocken()
    end

    local function ast_insert(op)
        if op == false then
            return
        end

        op.posFirst = nil
        op.posLast  = nil

        if op.type != nil then
            op.n_type = NumType(op.type)
            if op.n_type < GTASM_ALLNUM then
                if op.n_type == GTASM_DNUM then
                    op.data = tonumber(op.data)
                else
                    op.convert = ConvertNum(op.data, op.type)
                end
            end
        end

        if addres_t == true then
            table.insert(addres_a.data, op)
        else
            table.insert(ast.arg[comma], op)
        end
    end

    local function set_addres(bool)
        addres_t = bool
        if bool then
            addres_a = {
                type = "addres",
                data = {}
            }
        else
            ast_insert(addres_a)
            addres_a = {}
        end
    end

    local function push_mem_type(size)
        debug.Trace()
        if addres_t == true then
            addres_a.data[#addres_a.data]["byte_size"] = size
        else
            ast.arg[comma][#ast.arg[comma]]["byte_size"] = size
        end
    end

    for k,v in pairs(lex) do -- clear all whitespaces
        if v.type != "whitespace" then
            table.insert(cl_lex, v)
        end
    end
    lex = cl_lex

    if #lex == 0 then
        return
    end

    while true do
        local op = nextop()

        if op.type == "end_line" then
            break
        end
        PrintTable(op)
        if op.type == "ident" then
            if label == false and oper == false and get_tocken(1).data == ":" then
                ast.label = op.data
                label = true
                nextop()
                continue

            elseif oper == false then
                ast.oper = op.data
                oper = true
                continue

            elseif GT_M_SIZE[op.data] then

                push_mem_type(GT_M_SIZE[op.data])
                continue
            else
                ast_insert(op)
                continue
            end

        elseif op.type == "symbol" then
            if op.data == "[" then
                set_addres(true)

            elseif op.data == "]" then
                set_addres(false)
            end

            continue
        elseif op.type == "unidentified" then
            if op.data == "," then
                comma = comma + 1
                ast.arg[comma] = {}
                continue
                
            end

        elseif op.type == "string_start" then
            if get_tocken(2).type == "string_end" then
                op = nextop()
                ast_insert(op)
                nextop()
                
                continue
            else
                -- error
            end

        elseif op.type == "number" or op.type == "bin_val" or op.type == "hex_val" then
            ast_insert(op)
            continue
        end

        if pos == #lex then
            break
        end
    end

    for k,v in pairs(ast.arg) do
        ast.arg[k] = v[1]
    end

    return ast
end
