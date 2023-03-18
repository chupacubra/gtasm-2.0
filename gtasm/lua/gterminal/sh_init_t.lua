gTerminal = gTerminal or {};

GT_COL_NIL = 0;
GT_COL_MSG = 1;
GT_COL_WRN = 2;
GT_COL_ERR = 3;
GT_COL_INFO = 4;
GT_COL_INTL = 5;
GT_COL_CMD = 6;
GT_COL_SUCC = 7;

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