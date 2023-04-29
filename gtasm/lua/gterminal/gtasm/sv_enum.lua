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

GT_E_SYNT_ADRB   = 1
GT_E_SYNT_STRE   = 2
GT_E_WTF         = 3
GT_E_UNKNWN_INST = 4
GT_E_UNKNWN_LBL  = 5
GT_E_ARG_MATCH   = 6
GT_E_STACK_OVER  = 7
GT_E_MEM_VAL     = 8
GT_E_MEM_ADDRES  = 9
GT_E_PIRATE      = 10
GT_E_STOP        = 11
GT_E_COMPILE     = 12
GT_E_INT_UNK     = 13

GT_BYTE  = 1
GT_WORD  = 2
GT_DOUBLE = 4 

GT_M_SIZE = {
	byte = 1,
	word = 2,
	double = 4,
}
 
GTASM_ERROR_LIST = {
	"Syntaxis: expected ] or [",
	"Syntaxis: expected '",
	"Syntaxis: wtf with this",
	"gTASM: unknown instruction",
	"gTASM: unknown jump label",
	"gTASM: argument not match",
	"gTASM: Stack overflow!",
	"MEMBLOCK error: it's not a value",
	"MEMBLOCK error: unknown addres",
	"YOU'RE USING PIRATE VERSION OF gTASM. The corporation has found out your location. Calling the FBI squad...",
	"Script stop (int 1)",
	"Compiler: you broken lexical tree. YOU ENJOED?",
	"Interrupt: interrupts under this id do not exist",
}