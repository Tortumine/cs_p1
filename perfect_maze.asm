|; constants
|; TODO :: fix bug, constant declaration create longs (16b)
|; but we need words (32b)
|; TODO :: check lines 94-107,maybe false word offset
|; but we need words (32b)
H_LINE = 0xFFFFFFFF
V_LINE = 0xC0C0C0C0
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

TEST_0 = 0xFFE1

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
	
	breakpoint.
	|; R5 = R3/R4 <==> dest_row = dest / nb_cols
	DIV(R3, R4, R5)	|; RC <- <RA> / <RB>
	|; R6 = R5*WORDS_PER_ROW <==> row_offset = dest_row*WORDS_PER_ROW
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
	CMPLEC(R11, 0x1, R11)
	BEQ(R11, horizontal)
	
	vertical:	|; open vertical connection
		ST(R31,0x0044)
		HALT()

	horizontal:	|; open horizontal connection
		MOVE(R1,R15)
		|; TODO :: "switch-case" on byte_offset (0,1,2 or 3)
		|; TODO :: adapt H0 case to H1,H2,H3
		horizontal_0:	|;case H0
			LD(R15, 0x0, R11)		|; RC <- <<RA>+CC>	(get table row0)
			ANDC(R11,OPEN_H_0, R12)	|; RC <- <RA> + C	(bit mask and table)
			ST(R12,0x0,R15)
			LD(R15, 0x20, R11)		|; RC <- <<RA>+CC>	(get table row1)
			ANDC(R11,OPEN_H_0, R12)	|; RC <- <RA> + C	(bit mask and table)
			ST(R12,0x20,R15)
			HALT()
		horizontal_1:	|;case H1	
		horizontal_2:	|;case H2
		horizontal_3:	|;case H3
		HALT()
	vhend:	|; vertical horizontal end
	
	HALT()
	
	
perfect_maze:
	|; connect test regs
	|; for horizontal : R3 = R2 +-1
	|; for vertical : R3 = R2 +-32
		CMOVE(33,R2) 
		CMOVE(65,R3)
		CMOVE(32,R4)
	
	PUSH(R4)	|;nb_cols
	PUSH(R2)	|;source	
	PUSH(R3)	|;dest
	PUSH(R1)	|;maze
	CALL(connect)
	DEALLOCATE(4)
