|; TODO connect function push-pop 
|; TODO :: modify code : literals to regs

.macro OPEN_H_0() {LONG(0xFFFFFFE1)}
.macro OPEN_H_1() {LONG(0xFFFFE1FF)}
.macro OPEN_H_2() {LONG(0xFFE1FFFF)}
.macro OPEN_H_3() {LONG(0xE1FFFFFF)}

.macro OPEN_V_0() {LONG(0xFFFFFF00)}
.macro OPEN_V_1() {LONG(0xFFFF00FF)}
.macro OPEN_V_2() {LONG(0xFF00FFFF)}
.macro OPEN_V_3() {LONG(0x00FFFFFF)}

|; constants
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

	DIVC(R3,NB_COLS,R5) 		|; dest_row = dest / nb_cols
	MULC(R5,WORDS_PER_ROW,R6) 	|; row_offset = dest_row*WORDS_PER_ROW
	
	DIVC(R3,NB_COLS,R5) 		|; dest_row = dest / nb_cols
	MULC(R5,WORDS_PER_ROW,R6) 	|; row_offset = dest_row*WORDS_PER_ROW
	
	|; source_col = source % nb_cols
	|; R7 = R2 % nb_cols
	|; a % n = a - (n * int(a/n)) 
	|; ==> source % nb_cols = source - (nb_cols * int(source/nb_cols))
	DIVC(R2,NB_COLS,R7) 		|; ans = source / nb_cols
	MULC(R7,NB_COLS,R7)			|; ans = ans * nb_cols
	SUB(R2, R7, R7)				|; source_col = source - ans
	
	DIVC(R7,CELLS_PER_WORD,R8)	|; word_offset_in_line = source_col / CELLS_PER_WORD
	ADD(R6, R8, R9)				|; word_offset = row_offset + word_offset_in_line
	
	|; byte_offset = source_col % CELLS_PER_WORD
	|; R10 = R7 % CELLS_PER_WORD
	DIVC(R7,CELLS_PER_WORD,R10) |; ans = source_col / CELLS_PER_WORD
	MULC(R10,CELLS_PER_WORD,R10)|; ans = ans * CELLS_PER_WORD
	SUB(R7, R10, R10)			|; source_col = source_col - ans
	
	|; R15 =  WORDS_PER_MEM_LINE * word_offset + source
	MULC(R9,CELLS_PER_WORD,R15)
	ADD(R15,R1,R15)
	
	|; vertical connection cf C L61->L75
	|; [if(dest - source > 1)==>verical] <==> [if(dest - source <= 0)==>verical]
	SUB(R3, R2, R11)
	CMPLEC(R11, 0x1, R11)
	BEQ(R11, horizontal)

	vertical:	|; open vertical connection
		
		|; Switch case
		CMPEQC(R10, 0x0, R11)
		BT(R11, vertical_0)	|; 0
		CMPEQC(R10, 0x1, R11)	
		BT(R11, vertical_1)	|; 1
		CMPEQC(R10, 0x2, R11)
		BT(R11, vertical_2)	|; 2
		CMPEQC(R10, 0x3, R11)	
		BT(R11, vertical_3)	|; 3
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
	
	DEALLOCATE(20)
		HALT()
	RTN()
	
	
perfect_maze:
	|; for horizontal : R3 = R2 +-1
	|; for vertical : R3 = R2 +-32
		CMOVE(2,R2) 
		CMOVE(33,R3)
		CMOVE(NB_COLS,R4)
	
	PUSH(R4)	|;nb_cols
	PUSH(R2)	|;source	
	PUSH(R3)	|;dest
	PUSH(R1)	|;maze
	CALL(connect)
	DEALLOCATE(4)
