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

function PT(arr,recurs)
    if recurs == nil then
        recurs = 0
    end
    local recursStr = ""
    for i=0,recurs do
        recursStr = recursStr .. "    "
    end

    for k,v in pairs(arr) do
        if type(v) == "table" then
            --print(recursStr..k,"=", type(v))
            PT(v,recurs + 1)
        else 
            --print(recursStr..k,"=",v)
        end
    end
end


local function isOperand(oper)
    return true
end

function astp(lex)
    local ast = {}
    local iter = 1
    local argmas = {}
    local arg_1  = {}
    
    for k,v in pairs(lex[1]) do
        if (v.type == "whitespace" or v.type ==  "unidentified")  and ast.oper == nil then
        else
            
            if #lex[1] == 1 then
                ast.oper = v.data
            end

            if lex[1][1]["data"] == "." then
                table.remove(lex[1],1)
                ast.directive = true
            end
            --[[
            if v.type == "label_end" and ast.label then
                --return
            elseif v.type == "label_end" and (ast.label == nil) then
                -- return error
            end

            if v.type == "label_start" then
                if lex[1][k+1].type == "label" then
                    ast.label = lex[1][k+1].data
                end
                PrintTable(ast)
            end
            --]]
            
            if v.type == "ident" and ast.oper == nil then
                if lex[1][k + 1]['data'] == ":" then -- проверка на метку
                    ast.label = v.data
                    print(v.data,"label")
                else
                    ast.oper = v.data
                end
            elseif not(v.type == "ident") and ast.oper == nil then --не идент значет ощибка!!!1

            end

            if ast.oper and not (v.data == ast.oper) then
                if v.data == "," then
                    table.insert(arg_1,argmas)
                    argmas = {}
                elseif not(v.type == "whitespace") then
                    table.insert(argmas,v)
                end
            end
        end
        PrintTable(ast)
    end

    if #argmas > 0 then
        table.insert(arg_1,argmas)
        argmas = {}
    end

    local skobk = {bstart = 0,bstop = 0,b = {},hstart = 0,hend = 0}
    local strg  = {bstart = 0,bstop = 0,b = {},hstart = 0,hend = 0}
    local stag  = false
    local sttag = false
    for k,v in pairs(arg_1) do
        --if #v > 1 then
            --if !((v[1]['data'] == "["  and  v[3]['data'] == "]") or (v[1]['data'] == "'"  and  v[3]['data'] == "'") or (v[1]['data'] == '"'  and  v[3]['data'] == '"')) then -- bruh
                --error(4)
            --end
        --end
        for kk,vv in pairs(v) do
            if vv.type == "hex_val" or vv.type == "bin_val" then
                arg_1[k][kk]["convert"] = ConvertNum(vv.data,vv.type)
            end

            if vv.data == "[" then
                if stag then
                    return false, 1, {POS_1 = skobk.hstart,POS_2 = vv.posFirst}
                end

                stag = true
                skobk.bstart = kk
                skobk.hstart = vv.posFirst
            elseif vv.data == "]" then
                if !stag then
                    return false, 1, {POS_1 = vv.posFirst}
                end

                stag = false
                skobk.bstop = kk
                skobk.type  = "addres"
                table.remove(skobk.b, 1)

                for i=skobk.bstart,skobk.bstop do
                    table.remove(arg_1[k], skobk.bstart)
                end
                
                table.insert(arg_1[k], skobk.bstart, skobk)
                skobk = {bstart = 0, bstop = 0, b = {}}
            end

            if vv.type == "string_start" then
                if sstag then
                    return false, 2, {POS_1 = strg.hstart, POS_2 = vv.posFirst}
                end

                sstag = true
                strg.bstart = kk
                strg.hstart = vv.posFirst
            elseif vv.type == "string_end" then
                sstag = false
                strg.bstop = kk
                strg.type  = "string"
                table.remove(strg.b, 1)

                for i=strg.bstart, strg.bstop do
                    table.remove(arg_1[k], strg.bstart)
                end
                
                table.insert(arg_1[k], strg.bstart, strg)
                strg  = {bstart = 0, bstop = 0, b = {}}
            end

            if stag then
                table.insert(skobk.b, vv)
            end
            
            if sstag then
                table.insert(strg.b, vv)
            end
        end
    end

    if stag then
        return false, 1, {POS_1 = skobk.hstart}
    end

    if sstag then
        return false, 2, {POS_1 = strg.hstart}
    end

    local fin_arg = {}
    for k,v in pairs(arg_1) do
        for kk,vv in pairs(v) do
            if vv.type == "addres" or vv.type == "string" then
                for kkk,vvv in pairs(vv.b) do
                    vv.b[kkk]["n_type"] = NumType(vv.b[kkk]["type"])
                end
                vv.data = vv.b
            end
            table.insert(fin_arg,{
                type = vv.type,
                n_type = NumType(vv.type),
                data = vv.data,
                convert = vv.convert
            })
        end
    end
    ast.arg = fin_arg

    PT(ast)
    return ast
end
--[[
function testast(lexx)
    local lex = lexx[1]
    local pos = 1
    local ast = {}

    local function getV(d)
        return lex[pos + d or 0]
    end

    local function removeSpaceAndTrash()
        local lpos = 1
        while true do
            if getV().type == "whitespace" or getV().type == "string_start" or getV().type == "string_end" or getV().type == "label_start" or getV().type == "label_end" then -- bruh
                table.remove(lex[pos])
            else
                lpos = lpos + 1
            end
            if lpos > #lex then

            end
        end
    end

    local function astInsert()
        
    end--[[
::Label:: db 0b10101, 0xdeadbeef, "skibidi", [R1]
lex ->  [:: - label_start]
        [Label -    label]
        [:: -   label_end]
        [whitespace]
        [db - ident]
        [whitespace]
        [0b10101 - bin_val]
        [, - symbol]
        [whitespace]
        [0xdeadbeef - hex_val]
        [, - symbol]
        [" - string_start]
        [skibidi - string]
        [" - string end]
        [, - symbol]
        [whitespace]
        [[ - simbol]
        [R1 - ident]
        [] - simbol]



NEED
    {
        label = "Label"
        commmand = "db"
        args = {
            1 = {0b10101, bin_val}
            2 = {deadbeef, hex_val}
            3 = {skibidi, string}
            4 = {R1, addres}
        }
    }
1 этап убираем все пробелы
lex ->  [:: - label_start]
        [Label -    label]
        [:: -   label_end]
        [db - ident]
        [0b10101 - bin_val]
        [, - symbol]
        [0xdeadbeef - hex_val]
        [, - symbol]
        [" - string_start]
        [skibidi - string]
        [" - string end]
        [, - symbol]
        [[ - simbol]
        [R1 - ident]
        [] - simbol]


2 этап делим на запятые
{
        [:: - label_start]
        [Label -    label]
        [:: -   label_end]
        [db - ident]
        [0b10101 - bin_val]
}
{
        [0xdeadbeef - hex_val]
}
{
        [" - string_start]
        [skibidi - string]
        [" - string end]
}
{
        [[ - simbol]
        [R1 - ident]
        [] - simbol]
}

3 этап определяем метку
label = "Label"
{
        [db - ident]
        [0b10101 - bin_val]
}
{
        [0xdeadbeef - hex_val]
}
{
        [" - string_start]
        [skibidi - string]
        [" - string end]
}
{
        [[ - simbol]
        [R1 - ident]
        [] - simbol]
}

4 этап определяем команду( берём первый идент)
label = "Label"
cmd   = "db"
{
        [0b10101 - bin_val]
}
{
        [0xdeadbeef - hex_val]
}
{
        [" - string_start]
        [skibidi - string]
        [" - string end]
}
{
        [[ - simbol]
        [R1 - ident]
        [] - simbol]
}

5 этап определяем строки
{
        [0b10101 - bin_val]
}
{
        [0xdeadbeef - hex_val]
}
{
        [skibidi - string]
}
{
        [[ - simbol]
        [R1 - ident]
        [] - simbol]
}

6 этап определяем адррес
{
        [0b10101 - bin_val]
}
{
        [0xdeadbeef - hex_val]
}
{
        [skibidi - string]
}
{
        [R1 - ident,address]
}

7 этап вносим в массив ast
    {
        label = "Label"
        commmand = "db"
        args = {
            1 = {data = "0b10101",convert = 21,type = GTASM_BVAL}
            2 = {data = "0xdeadbeef",convert = 3 735 928 559, type = GTASM_HVAL}
            3 = {data = "skibidi', type = GTASM_STR}
            4 = {addres,data = {R1=}
        }
    }
--]]
--[[
    while true do
        break
    end
end
--]]
local text = "::Label:: db 'asdss' ,0b0101"
local loex = lexer(text)
a = astp(loex)
print("")
PrintTable(a)