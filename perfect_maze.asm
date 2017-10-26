|; TODO :: modify code : literals to regs
|; TODO :: ADD AS MUCH MACROS AS YOU CAN
|; TODO :: clear unnecessary cont
|; TODO MAYBE :: create swap function

|; MACROS
	|; macros to define bitmasks (cf connect() L ***LINENUMBER***)
	.macro OPEN_H_0() {LONG(0xFFFFFFE1)}
	.macro OPEN_H_1() {LONG(0xFFFFE1FF)}
	.macro OPEN_H_2() {LONG(0xFFE1FFFF)}
	.macro OPEN_H_3() {LONG(0xE1FFFFFF)}

	.macro OPEN_V_0() {LONG(0xFFFFFF00)}
	.macro OPEN_V_1() {LONG(0xFFFF00FF)}
	.macro OPEN_V_2() {LONG(0xFF00FFFF)}
	.macro OPEN_V_3() {LONG(0x00FFFFFF)}

	|; Reg[Rc] <- Reg[Ra] mod C (Rc should be different from Ra)
	.macro MODC(Ra, C, Rc) DIVC(Ra, C, Rc) MULC(Rc, C, Rc) SUB(Ra, Rc, Rc)

|; CONSTANTS
|; needs to be edited
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

|;FUNCTIONS

|;----------
|;connect
|;----------
|;	PARAMETERS
|;		maze: address of the first word of the maze
|;		source : cell number of the present location in the maze
|;		dest : cell number of the destination
|;		nb_cols : number of columns in the maze
|;
|;	REGISTER
|;		maze -> R1
|;		source -> R2
|;		dest -> R3
|;		nb_cols -> R4
|;		
|;		dest_row -> R5					= dest / nb_cols
|;		row_offset -> R6				= dest_row * WORDS_PER_ROW
|;		source_col -> R7				= source % nb_cols
|;		word_offset_in_line -> R8		= source_col / CELLS_PER_WORD
|;		word_offset -> R9				= row_offset + word_offset_in_line
|;		byte_offset -> R10				= source_col % CELLS_PER_WORD
|;----------
|;TMP vars
|;----------
|;tmp1 -> R11
|;tmp2 -> R12
|;tmp3 -> R13
|;tmp4 -> R14
|;tmp5 -> R15		= pointer to the first word to edit

connect:
|; Saving local variables
	PUSH(LP)
	PUSH(BP)
	MOVE(SP, BP)
	ALLOCATE(20)
	PUSH(R1)
	PUSH(R2)
	PUSH(R3)
	PUSH(R4)
	PUSH(R5)
	PUSH(R6)
	PUSH(R7)
	PUSH(R8)
	PUSH(R9)
	PUSH(R10)
	PUSH(R11)
	PUSH(R12)
	PUSH(R13)
	PUSH(R14)
	PUSH(R15)
	PUSH(R16)
	PUSH(R17)
	PUSH(R18)
	PUSH(R19)
	PUSH(R20)
	
	|; Load Parameters
	LD(BP, -12, R1) |;Get param Maze
	LD(BP, -16, R2) |;Get param source
	LD(BP, -20, R3)	|;Get param dest
	LD(BP, -24, R4) |;Get param nb_cols

	|; if(source > dest) -> swap
	CMPLT(R3, R2, R11)			|;check if R2<R3
	BEQ(R11, noswaplabel)		|; IF <R11>!=0 THEN PC <- LABEL
		MOVE(R3, R11)
		MOVE(R2, R3)
		MOVE(R11,R2)
	noswaplabel: 		|; no swap label

	
	DIV(R3,R4,R5) 		|; dest_row = dest / nb_cols
	MULC(R5,WORDS_PER_ROW,R6) 	|; row_offset = dest_row*WORDS_PER_ROW
	DIV(R3,R4,R5) 		|; dest_row = dest / nb_cols
	MULC(R5,WORDS_PER_ROW,R6) 	|; row_offset = dest_row*WORDS_PER_ROW
	
	
	MOD(R2,R4,R7)				|; source_col = source % nb_cols
	
	DIVC(R7,CELLS_PER_WORD,R8)	|; word_offset_in_line = source_col / CELLS_PER_WORD
	ADD(R6, R8, R9)				|; word_offset = row_offset + word_offset_in_line
	
	
	MODC(R7,CELLS_PER_WORD,R10)	|; byte_offset = source_col % CELLS_PER_WORD
	
	|; R15 =  WORDS_PER_MEM_LINE * word_offset + source
	MULC(R9,CELLS_PER_WORD,R15)
	ADD(R15,R1,R15)
	
	|; Branch depending on the orientation of the connection
	|; [if(dest - source > 1)==>vertical] <==> [if(dest - source <= 0)==>verical]
	SUB(R3, R2, R11)
	CMPLEC(R11, 0x1, R11)
	BEQ(R11, horizontal)
	
	|; vertical connection (cf perfect_mase.c L61->L75)
	vertical:	|; open vertical connection
		
		|; Switch case depending on the byte_offset
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
		
		|; Switch case depending on the byte_offset
		CMPEQC(R10, 0x0, R11)
		BT(R11, horizontal_0)	|; 0
		CMPEQC(R10, 0x1, R11)	
		BT(R11, horizontal_1)	|; 1
		CMPEQC(R10, 0x2, R11)	
		BT(R11, horizontal_2)	|; 2
		CMPEQC(R10, 0x3, R11)	
		BT(R11, horizontal_3)	|; 3
		horizontal_0:	|;case H0
			LD(R15, 0x0, R11)		|; get table row0
			CMOVE(OPEN_H0, R12)		|; get bit mask adr
			LD(R12,0x0,R13)			|; get bit mask
			AND(R11, R13, R14)		|; 			
			ST(R14, 0x0, R15)		|; <RA>+0x0 <- <RC>	|; H'
			ST(R14, 0x20, R15)		|; <RA>+0x20 <- <RC>	|; H''
			BEQ(R31, vhend)			|; quit the conditional structure
		horizontal_1:	|;case H1	
			LD(R15, 0x0, R11)		|; get table row0
			CMOVE(OPEN_H1, R12)		|; get bit mask adr
			LD(R12,0x0,R13)			|; get bit mask
			AND(R11, R13, R14)		|; 			
			ST(R14, 0x0, R15)		|; <RA>+0x0 <- <RC>	|; H'
			ST(R14, 0x20, R15)		|; <RA>+0x20 <- <RC>	|; H''
			BEQ(R31, vhend)			|; quit the conditional structure
		horizontal_2:	|;case H2		
			LD(R15, 0x0, R11)		|; get table row0
			CMOVE(OPEN_H2, R12)		|; get bit mask adr
			LD(R12,0x0,R13)			|; get bit mask
			AND(R11, R13, R14)		|; 			
			ST(R14, 0x0, R15)		|; <RA>+0x0 <- <RC>	|; H'
			ST(R14, 0x20, R15)		|; <RA>+0x20 <- <RC>	|; H''
			BEQ(R31, vhend)			|; quit the conditional structure
		horizontal_3:	|;case H3
			LD(R15, 0x0, R11)		|; get table row0
			CMOVE(OPEN_H3, R12)		|; get bit mask adr
			LD(R12,0x0,R13)			|; get bit mask
			AND(R11, R13, R14)		|; 			
			ST(R14, 0x0, R15)		|; <RA>+0x0 <- <RC>	|; H'
			ST(R14, 0x20, R15)		|; <RA>+0x20 <- <RC>	|; H''
			BEQ(R31, vhend)			|; quit the conditional structure
	vhend:	|; vertical horizontal end
	
	|; exit operation
	POP(R20)
	POP(R19)
	POP(R18)
	POP(R17)
	POP(R16)
	POP(R15)
	POP(R14)
	POP(R13)
	POP(R12)
	POP(R11)
	POP(R10)
	POP(R9)
	POP(R8)
	POP(R7)
	POP(R6)
	POP(R5)
	POP(R4)
	POP(R3)
	POP(R2)
	POP(R1)
	
	MOVE(R31,r0) |; return 0x0
	MOVE(BP,SP)
	POP(BP)
	POP(LP)
	RTN()
	
	
perfect_maze:
	|; This is an example of connect function call
	|; It requires 3 params
	|; Source cell, Destination cell, Number of Columns
	|; for horizontal : R3 = R2 +-1
	|; for vertical : R3 = R2 +-32
	.breakpoint
		CMOVE(3,R2) 
		CMOVE(33,R3)
		CMOVE(NB_COLS,R4)
		PUSH(R4)	|;nb_cols
		PUSH(R3)	|;source	
		PUSH(R2)	|;dest
		PUSH(R1)	|;maze
		CALL(connect)	
		DEALLOCATE(4)
	
