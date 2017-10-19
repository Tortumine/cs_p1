.macro OPEN_H_0() {LONG(0xFFFFFFE1)}
.macro OPEN_H_1() {LONG(0xFFFFE1FF)}
.macro OPEN_H_2() {LONG(0xFFE1FFFF)}
.macro OPEN_H_3() {LONG(0xE1FFFFFF)}

.macro OPEN_V_0() {LONG(0xFFFFFF00)}
.macro OPEN_V_1() {LONG(0xFFFF00FF)}
.macro OPEN_V_2() {LONG(0xFF00FFFF)}
.macro OPEN_V_3() {LONG(0x00FFFFFF)}

|; constants
|; TODO :: fix bug, constant declaration create words (16b)
|; but we need Longs (32b)
|; TODO :: check lines 94-107,maybe false word offset
|; but we need Longs (32b)
H_LINE = 0xFFFFFFFF
V_LINE = 0xC0C0C0C0
NB_ROWS = 8
NB_COLS = 32
NB_CELLS = 256
WORDS_PER_MEM_LINE = 8
MEM_LINES_PER_ROW = 8
WORDS_PER_ROW = 64
NB_MAZE_WORDS = 512 
CELLS_PER_WORD = 4

TEST_0 = 0xFFE1
|;TEST_1

OPEN_H0:
    OPEN_H_0()
OPEN_H1:
    OPEN_H_1()
OPEN_H2:
    OPEN_H_2()
OPEN_H3:
    OPEN_H_3()

OPEN_V0:
    OPEN_V_0()
OPEN_V1:
    OPEN_V_1()
OPEN_V2:
    OPEN_V_2()
OPEN_V3:
    OPEN_V_3()

|;Functions

|;row_from_index
|;PARAMETERS
|;index
|;nb_col
|;REGISTER
|;R1 -> index
|;R2 -> nb_cols
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
|;dest_row -> R5				= dest / nb_cols
|;row_offset -> R6				= dest_row * WORDS_PER_ROW
|;source_col -> R7				= source % nb_cols
|;word_offset_in_line -> R8		= source_col / CELLS_PER_WORD
|;word_offset -> R9				= row_offset + word_offset_in_line
|;byte_offset -> R10			= source_col % CELLS_PER_WORD
|;----------
|;TMP vars
|;----------
|;tmp1 -> R11
|;tmp2 -> R12
|;tmp3 -> R13
|;tmp4 -> R14
|;tmp5 -> R15
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
	
	MOVE(R9,R15)	|;tmp5 -> R15 == address to edit
	

	
	|; vertical connection cf C L61->L75
	|; [if(dest - source > 1)==>verical] <==> [if(dest - source <= 0)==>verical]
	SUB(R3, R2, R11)
	CMPLEC(R11, 0x1, R11)
	BEQ(R11, horizontal)

	vertical:	|; open vertical connection
		MUL(R15, R9, R15)		|; RC <- <RA> * <RB>
		ADDC(R15,0x40,R15) 	|; add a offset vertical cut
		|; Switch case
		CMPEQC(R10, 0x0, R11)
		BT(R11, vertical_0)	|; 0
		CMPEQC(R10, 0x1, R11)	
		BT(R11, vertical_1)	|; 0
		CMPEQC(R10, 0x2, R11)
		BT(R11, vertical_2)	|; 0
		CMPEQC(R10, 0x3, R11)	
		BT(R11, vertical_3)	|; 0
		vertical_0:				|;case H0
			LD(R15, 0x60, R11)		|; get table row0
			CMOVE(OPEN_V0, R12)		|; get bit mask adr
			LD(R12,0x0,R13)			|; get bit mask
			AND(R11, R13, R14)		|; 			
			ST(R14, 0x60, R15)		
			ST(R14, 0x80, R15)		
			ST(R14, 0xA0, R15)
			ST(R14, 0xC0, R15)			
			BEQ(R31, vhend)			|; quit the conditional structure
			
		vertical_1:				|;case H1	
			LD(R15, 0x60, R11)		|; get table row0
			CMOVE(OPEN_V1, R12)		|; get bit mask adr
			LD(R12,0x0,R13)			|; get bit mask
			AND(R11, R13, R14)		|; 			
			ST(R14, 0x60, R15)		
			ST(R14, 0x80, R15)		
			ST(R14, 0xA0, R15)
			ST(R14, 0xC0, R15)		
			BEQ(R31, vhend)			|; quit the conditional structure
			
		vertical_2:				|;case H2
			LD(R15, 0x60, R11)		|; get table row0
			CMOVE(OPEN_V2, R12)		|; get bit mask adr
			LD(R12,0x0,R13)			|; get bit mask
			AND(R11, R13, R14)		|; 			
			ST(R14, 0x60, R15)		
			ST(R14, 0x80, R15)		
			ST(R14, 0xA0, R15)
			ST(R14, 0xC0, R15)			
			BEQ(R31, vhend)			|; quit the conditional structure
			
		vertical_3:				|;case H3
			LD(R15, 0x60, R11)		|; get table row0
			CMOVE(OPEN_V3, R12)		|; get bit mask adr
			LD(R12,0x0,R13)			|; get bit mask
			AND(R11, R13, R14)		|; 			
			ST(R14, 0x60, R15)		
			ST(R14, 0x80, R15)		
			ST(R14, 0xA0, R15)
			ST(R14, 0xC0, R15)			
			BEQ(R31, vhend)			|; quit the conditional structure

		
	horizontal:	|; open horizontal connection
		|; Switch case
		CMPEQC(R10, 0x0, R11)
		BT(R11, horizontal_0)	|; 0
		CMPEQC(R10, 0x1, R11)	
		BT(R11, horizontal_1)	|; 1
		CMPEQC(R10, 0x2, R11)	
		BT(R11, horizontal_2)	|; 2
		CMPEQC(R10, 0x3, R11)	
		BT(R11, horizontal_3)	|; 3
		HALT()
		horizontal_0:	|;case H0
			LD(R15, 0x0, R11)		|; get table row0
			CMOVE(OPEN_H0, R12)		|; get bit mask adr
			LD(R12,0x0,R13)			|; get bit mask
			AND(R11, R13, R14)		|; 			
			ST(R14, 0x0, R15)		| <RA>+0x0 <- <RC>	|; H'
			ST(R14, 0x20, R15)		| <RA>+0x20 <- <RC>	|; H''
			BEQ(R31, vhend)			|; quit the conditional structure
		horizontal_1:	|;case H1	
			LD(R15, 0x0, R11)		|; get table row0
			CMOVE(OPEN_H1, R12)		|; get bit mask adr
			LD(R12,0x0,R13)			|; get bit mask
			AND(R11, R13, R14)		|; 			
			ST(R14, 0x0, R15)		| <RA>+0x0 <- <RC>	|; H'
			ST(R14, 0x20, R15)		| <RA>+0x20 <- <RC>	|; H''
			BEQ(R31, vhend)			|; quit the conditional structure
		horizontal_2:	|;case H2		
			LD(R15, 0x0, R11)		|; get table row0
			CMOVE(OPEN_H2, R12)		|; get bit mask adr
			LD(R12,0x0,R13)			|; get bit mask
			AND(R11, R13, R14)		|; 			
			ST(R14, 0x0, R15)		| <RA>+0x0 <- <RC>	|; H'
			ST(R14, 0x20, R15)		| <RA>+0x20 <- <RC>	|; H''
			BEQ(R31, vhend)			|; quit the conditional structure
		horizontal_3:	|;case H3
			LD(R15, 0x0, R11)		|; get table row0
			CMOVE(OPEN_H3, R12)		|; get bit mask adr
			LD(R12,0x0,R13)			|; get bit mask
			AND(R11, R13, R14)		|; 			
			ST(R14, 0x0, R15)		| <RA>+0x0 <- <RC>	|; H'
			ST(R14, 0x20, R15)		| <RA>+0x20 <- <RC>	|; H''
			BEQ(R31, vhend)			|; quit the conditional structure
	vhend:	|; vertical horizontal end
	
	HALT()
	
	
perfect_maze:
	|; connect test regs
	|; for horizontal : R3 = R2 +-1
	|; for vertical : R3 = R2 +-32
		CMOVE(4,R2) 
		CMOVE(5,R3)
		CMOVE(NB_COLS,R4)
	
	PUSH(R4)	|;nb_cols
	PUSH(R2)	|;source	
	PUSH(R3)	|;dest
	PUSH(R1)	|;maze
	CALL(connect)
	DEALLOCATE(4)
