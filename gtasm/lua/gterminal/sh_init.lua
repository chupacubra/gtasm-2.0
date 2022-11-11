gTerminal = gTerminal or {};

GT_COL_NIL = 0;
GT_COL_MSG = 1;
GT_COL_WRN = 2;
GT_COL_ERR = 3;
GT_COL_INFO = 4;
GT_COL_INTL = 5;
GT_COL_CMD = 6;
GT_COL_SUCC = 7;
--[[
GTASM_VAR = 0
GTASM_REG = 1
GTASM_DNUM = 2
GTASM_ADDR = 3
GTASM_BNUM = 4
GTASM_HNUM = 5
GTASM_STR  = 6
GTASM_ALL  = 7
--]]

GTASM_DNUM   = 0
GTASM_HNUM   = 1
GTASM_BNUM   = 2
GTASM_ALLNUM = 3
GTASM_STR    = 4
GTASM_ALLMEM = 5
GTASM_ADDR   = 6
GTASM_VAR    = 7
GTASM_REG    = 8
GTASM_NOARG  = 9  

GTASM_ERROR_LIST = {
	"Syntaxis: expected ] or [",
	"Syntaxis: expected '",
	"Syntaxis: wtf with this",
	"gTASM: unknown instruction",
	"gTASM: unknown jump label",
	"gTASM: argument not match",
	"MEMBLOCK error: it's not a value",
	"MEMBLOCK error: unknown addres"
}

function gTerminal:ColorFromIndex(code)
	if (code == GT_COL_MSG) then
		return Color(200, 200, 200);
	elseif (code == GT_COL_WRN) then
		return Color(255, 250, 50);
	elseif (code == GT_COL_ERR) then
		return Color(255, 50, 50);
	elseif (code == GT_COL_INFO) then
		return Color(60, 100, 250);
	elseif (code == GT_COL_INTL) then
		return Color(60, 250, 250);
	elseif (code == GT_COL_CMD) then
		return Color(125, 125, 125);
	elseif (code == GT_COL_SUCC) then
		return Color(75, 255, 80);
	end;

	return Color(50, 50, 50);
end;