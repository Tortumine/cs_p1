|; constants
H_LINE = 0xFFFFFFFF
V_LINE = 0xC0C0C0C0
TEST_1 = 0xE1FF
TEST_2 = 0xFFE1
OPEN_V_0 = 0xFFFFFF00
OPEN_V_1 = 0xFFFF00FF
OPEN_V_2 = 0xFF00FFFF
OPEN_V_3 = 0x00FFFFFF
OPEN_H_0 = 0xFFFFFFE1
OPEN_H_1 = 0xFFFFE1FF
OPEN_H_2 = 0xFFE1FFFF
OPEN_H_3 = 0xE1FFFFFF
NB_ROWS = 8
NB_COLS = 32
NB_CELLS = 256
WORDS_PER_MEM_LINE = 8
MEM_LINES_PER_ROW = 8
WORDS_PER_ROW = 64
NB_MAZE_WORDS = 512 
CELLS_PER_WORD = 4

|;Functions

|;row_from_index
|;PARAMETERS
|;index
|;nb_col
|;REGISTER
|;R1 -> index
|;R2 -> nb_col
|;R0 -> return
row_from_index:
PUSH(LP)
PUSH(BP)
MOVE(SP, BP)
PUSH(R1)
PUSH(R2)
LD(BP, -16, R1) |; Get params Index
LD(BP, -12, R2) |; get params nb_col
DIV(R1, R2, R0) |; Index / nb_col
POP(R2)
POP(R1)
POP(BP)
POP(LP)
RTN()

|;----------
|;connect
|;----------
|;PARAMETERS
|;maze: address of the first word of the maze
|;source :
|;dest :
|;nb_cols 
|;
|;REGISTER
|;maze -> R1
|;source -> R2
|;dest -> R3
|;nb_cols -> R4
|;dest_row -> R5
|;row_offset -> R6
|;source_col -> R7
|;word_offset_in_line -> R8
|;word_offset -> R9
|;byte_offset -> R10
|;----------
|;TMP vars
|;----------
|;tmp1 -> R11
connect:
	PUSH(LP)
	PUSH(BP)
	MOVE(SP, BP)
	ALLOCATE(20)
	|; TODO :: create swap function
	|; if(source > dest) -> swap
	CMPLT(R3, R2, R11)			|;check if R2<R3
	BEQ(R11, noswaplabel)		|; IF <R11>!=0 THEN PC <- LABEL
		MOVE(R3, R11)
		MOVE(R2, R3)
		MOVE(R11,R2)
	noswaplabel: 		|; no swap label

	|; TODO :: create functions cf C L54->L59
	|; row_from_index & col_from_index
	
	|; row_offset = (dest/nb_cols)*WORDS_PER_ROW
	|; R5 = R3/R4 <==> dest_row = dest / nb_cols
	DIV(R3, R4, R5)	|; RC <- <RA> / <RB>
	MULC(R5, WORDS_PER_ROW, R6)
	|; modulo : a % b == a & (b - 1)
	SUBC(R4, 0x1, R11)
	AND(R2,R11,R7)
	
	DIV(R7, CELLS_PER_WORD, R8)
	ADD(R6, R8, R9)
	|; modulo
	CMOVE(CELLS_PER_WORD,R11) |; need to init a reg for SUBC()
	SUBC(R11, 0x1, R11)
	AND(R7,R11,R10)
	
	|; vertical connection cf C L61->L75
	|; [if(dest - source > 1)==>verical] <==> [if(dest - source <= 0)==>verical]
	SUB(R3, R2, R11)
	CMPLEC(R11, 0x1, R11)	|; RC <- <RA> <= C
	BEQ(R11, vertical)	
	horizontal:
		LD(R1, 0x0, R11)		|; RC <- <<RA>+CC>	(get table row0)
		ANDC(R11,TEST_1, R12)	|; RC <- <RA> + C	(bit mask and table)
	 	ST(R12,0x0,R1)
		LD(R1, 0x20, R11)		|; RC <- <<RA>+CC>	(get table row1)
		ANDC(R11,TEST_1, R12)	|; RC <- <RA> + C	(bit mask and table)
	 	ST(R12,0x20,R1)
		HALT()
	vertical:
	 	ST(R31,0x0044)
		HALT()
	vhend:	|; vertical horizontal end
	
	HALT()
	
	
perfect_maze:
	|; connect test regs
	|; for horizontal : R3 = R2 +-1
	|; for vertical : R3 = R2 +-32
		CMOVE(0x45,R2) 
		CMOVE(0x46,R3) |; 77 || 46
		CMOVE(32,R4)
	
	PUSH(R4)	|;nb_cols
	PUSH(R2)	|;source	
	PUSH(R3)	|;dest
	PUSH(R1)	|;maze
	CALL(connect)
	DEALLOCATE(4)
