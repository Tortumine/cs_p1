|; TODO :: ADD AS MUCH MACROS AS YOU CAN
|; TODO :: clean unnecessary CONSTANTS
|; TODO :: find a better name for the "STUFF" part
|; TODO :: Connect integration in the perfect maze function
|; TODO :: Write a description for perfect_maze function

|;*****************************************************************************
|; MACROS
|;*****************************************************************************
	
		|; Reg[Rc] <- Reg[Ra] mod C (Rc should be different from Ra)
	.macro MODC(Ra, C, Rc) DIVC(Ra, C, Rc) MULC(Rc, C, Rc) SUB(Ra, Rc, Rc)

	|; macros to define bitmasks (cf connect() L ***LINENUMBER***)
	.macro OPEN_H_0() {LONG(0xFFFFFFE1)}
	.macro OPEN_H_1() {LONG(0xFFFFE1FF)}
	.macro OPEN_H_2() {LONG(0xFFE1FFFF)}
	.macro OPEN_H_3() {LONG(0xE1FFFFFF)}

	.macro OPEN_V_0() {LONG(0xFFFFFF00)}
	.macro OPEN_V_1() {LONG(0xFFFF00FF)}
	.macro OPEN_V_2() {LONG(0xFF00FFFF)}
	.macro OPEN_V_3() {LONG(0x00FFFFFF)}
	
	|; Swap registers macro
	|; swap Ra and Rb using stack
	.macro SWAP(Ra,Rb){
		PUSH(Ra)
		MOVE(Rb, Ra)
		POP(Rb)
	}
	
	|; Horizontal opening macro
	|; 	Get the name of the caller and create an opening at the corresponding address
	.macro HOR(C){
		LD(R15, 0x0, R11)			|; get table row0
			CMOVE(C, R12)		|; get bit mask adr
			LD(R12,0x0,R13)			|; get bit mask
			AND(R11, R13, R14)		|; 			
			ST(R14, 0x0, R15)		|; <RA>+0x0 <- <RC>		|; H'
			ST(R14, 0x20, R15)		|; <RA>+0x20 <- <RC>	|; H''
	}
	|; Vertical opening macro
	|; Get the name of the caller and create an opening at the corresponding address
	.macro VER(C){
		LD(R15, 0x60, R11)		|; get table row0
			CMOVE(C, R12)		|; get bit mask adr
			LD(R12,0x0,R13)			|; get bit mask
			AND(R11, R13, R14)		|; 			
			ST(R14, 0x60, R15)		
			ST(R14, 0x80, R15)		
			ST(R14, 0xA0, R15)
			ST(R14, 0xC0, R15)			
	}
	
|;*****************************************************************************
|; CONSTANTS
|;*****************************************************************************

NB_ROWS = 8
NB_COLS = 32
NB_CELLS = 256

WORDS_PER_MEM_LINE = 8
MEM_LINES_PER_ROW = 8
WORDS_PER_ROW = 64
NB_MAZE_WORDS = 512 
CELLS_PER_WORD = 4

|;*****************************************************************************
|; STUFF
|;*****************************************************************************

|; 8 words saved for the visited bitmap
neighbours__:
	STORAGE(4)  

|; callers for LONG bit-masks
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
|;*****************************************************************************
|;FUNCTIONS
|;*****************************************************************************


|;---------------------------------------------------------
|; connect ( maze, source, destination, number of columns )
|;---------------------------------------------------------
|;	DESCRIPTION
|;		This function get an origin cell, a destination cell and horizontal length of the maze
|;		The origin and the destination cells must be neighbours
|;		
|;		This function modify the memory to create a connexion between the origin and the destination 
|;		
|;		It always return 0x0
|;		
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
|;		dest_row -> R5				= dest / nb_cols
|;		row_offset -> R6			= dest_row * WORDS_PER_ROW
|;		source_col -> R7			= source % nb_cols
|;		word_offset_in_line -> R8	= source_col / CELLS_PER_WORD
|;		word_offset -> R9			= row_offset + word_offset_in_line
|;		byte_offset -> R10			= source_col % CELLS_PER_WORD
|;		----------
|;		TMP vars
|;		----------
|;		R11	<- tmp1
|;		R12	<- tmp2
|;		R13	<- tmp3
|;		R14 <- tmp4
|;		R15 <- tmp5		= pointer to the first word to edit

connect:
|; Saving local variables form the caller
	PUSH(LP)
	PUSH(BP)
	MOVE(SP, BP)
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
	
	|; Load Parameters
	LD(BP, -12, R1) |;Get param Maze
	LD(BP, -16, R2) |;Get param source
	LD(BP, -20, R3)	|;Get param dest
	LD(BP, -24, R4) |;Get param nb_cols
	|; if(source > dest) -> swap
	CMPLT(R3, R2, R11)			|;check if R2<R3
	BEQ(R11, noswaplabel)		|; IF <R11>!=0 THEN PC <- LABEL
		SWAP(R2,R3)			|; swap R2 and R3
	noswaplabel: 				|; no swap label

	|; Offset calculation
	DIV(R3,R4,R5) 				|; dest_row = dest / nb_cols
	MULC(R5,WORDS_PER_ROW,R6) 	|; row_offset = dest_row*WORDS_PER_ROW
	DIV(R3,R4,R5) 				|; dest_row = dest / nb_cols
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
		vertical_0:				|;case V0
			VER(OPEN_V0)			|; call the macro for vertical opening
			BEQ(R31, vhend)			|; quit the conditional structure
			
		vertical_1:				|;case V1	
			VER(OPEN_V1)			|; call the macro for vertical opening
			BEQ(R31, vhend)			|; quit the conditional structure
		
		vertical_2:				|;case V2
			VER(OPEN_V2)			|; call the macro for vertical opening
			BEQ(R31, vhend)			|; quit the conditional structure
			
		vertical_3:				|;case V3
			VER(OPEN_V3)			|; call the macro for vertical opening
			BEQ(R31, vhend)			|; quit the conditional structure

		
	horizontal:	|; open horizontal connection
		
		|; Switch case depending on the byte_offset
		CMPEQC(R10, 0x0, R11)
		BT(R11, horizontal_0)|; 0
		CMPEQC(R10, 0x1, R11)	
		BT(R11, horizontal_1)|; 1
		CMPEQC(R10, 0x2, R11)	
		BT(R11, horizontal_2)|; 2
		CMPEQC(R10, 0x3, R11)	
		BT(R11, horizontal_3)|; 3
		
		horizontal_0:			|;case H0
			HOR(OPEN_H0)			|; call the macro for horizontal opening
			BEQ(R31, vhend)			|; quit the conditional structure
			
		horizontal_1:			|;case H1	
			HOR(OPEN_H1)			|; call the macro for horizontal opening
			BEQ(R31, vhend)			|; quit the conditional structure
			
		horizontal_2:			|;case H2		
			HOR(OPEN_H2)			|; call the macro for horizontal opening
			BEQ(R31, vhend)			|; quit the conditional structure
			
		horizontal_3:			|;case H3
			HOR(OPEN_H3)			|; call the macro for horizontal opening
			BEQ(R31, vhend)			|; quit the conditional structure
			
	vhend:	|; vertical horizontal end
	
	|; exit operations
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
	
	MOVE(BP,SP)
	POP(BP)
	POP(LP)
	RTN()
	

|;---------------------------------------------------------
|; perfect_maze ( maze, rows, cols, visited , current cell )
|;---------------------------------------------------------	
|;	DESCRIPTION
|;		
|;		
|;	PARAMETERS
|;
|;
|;
|;
|;
|;	REGISTERS
|;		R1 	<- Maze
|;		R2 	<- Rows
|;		R3 	<- Cols
|;		R4 	<- Visited
|;		R5 	<- CurrentCell
|;
|;		R6 	<- col
|;		R7 	<- row
|;		R8 	<- n_valid_neighbours
|;		R9 	<- neighbours pointer
|;		R10	<- neighbours offset
|;		----------
|;		TMP vars
|;		----------
|;		R11	<- tmp1
|;		R12	<- tmp2
|;		R13	<- tmp3
|;		R14	<- tmp4
|;----------
perfect_maze:
	PUSH(LP)
	PUSH(BP)
	MOVE(SP, BP)
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

	|; Load Parameters
	LD(BP, -12, R1) |;Get param Maze
	LD(BP, -16, R2) |;Get param Rows
	LD(BP, -20, R3)	|;Get param Cols
	LD(BP, -24, R4) |;Get param Visited
	LD(BP, -28, R5) |;Get param CurrentCell
	
	CMOVE(36,R5)	|; index control for tests
	
	|; calculate position
	MOD(R5,R3,R6) 	|; col
	DIV(R5,R3,R7)	|; row
	
	|; visited[curr_cell / 32]  =  visited[curr_cell / 32]  ||  (1 << (curr_cell % 32));
	|; used regs : R11 -> R15
		|; R8 <- (1 << Current_cell%32)
		MODC(R5,0x20,R14)
		CMOVE(1, R15)
		SHL(R15, R14, R11)	|;curent_mask set
		
		|; R12 = visited[curr_cell / 32]
		DIVC(R5,0x20,R14)		|; visited offset
		ADD(R14,R4,R15)			|; get visited_mask address
		LD(R15, 0x0, R12)		|; load visited mask
		
		OR(R11,R12,R13)			|; apply bit-mask
		ST(R13, 0x0, R15)		|; save bit-mask
	
	|; Void valid neighbours creation	
		CMOVE(0x0,R8)			|; n_valid_neighbours
		CMOVE(neighbours__, R9)	|;int neighbours[4]
	|; neighbours check_list
	|; used tmps : 
	|; R10 
		|; LEFT
			BEQ(R6,noleft)		|; if (col == 0) GOTO: noleft
				SUBC(R5, 0x1, R10)	|; R10 <= currentCell - 1
				ST(R10, 0x0, R9)	|; save left (R10)
				ADDC(R8,0x1,R8)		|; update n_valid_neighbours
			noleft:
			
		|; RIGHT
			SUBC(R3, 0x1, R10)	|; R10 <= nb_cols - 1
			CMPLT(R6, R10, R10)	|; RC <- <RA> <  <RB>
			BEQ(R10,noright)	|; if (col < nb_cols - 1) GOTO: noright
				ADDC(R5, 0x1, R10)	|; R10 <= currentCell + 1 
					MULC(R8,0x4,R11)	|;neighbours[R8]
					ADD(R9,R11,R11)
				ST(R10, 0x0, R11)	|; save right (R10)
				ADDC(R8,0x1,R8)		|; update n_valid_neighbours
			noright:
			
		|; TOP
			BEQ(R7,notop)		|; if (row == 0) GOTO: notop
				SUBC(R5, 0x20, R10)	|; R10 <= currentCell - 32
					MULC(R8,0x4,R11)	|;neighbours[R8]
					ADD(R9,R11,R11)
				ST(R10, 0x0, R11)	|; save top (R10)
				ADDC(R8,0x1,R8)		|; update n_valid_neighbours
			notop:
			
		|; BOTTOM
			SUBC(R2, 0x1, R10)	|; R10 <= nb_rows - 1	
			CMPLT(R7, R10, R10)	|; RC <- <RA> <  <RB>
			BEQ(R10,nobottom)		|; if (row < nb_rows - 1) GOTO: nobottom
				ADDC(R5, 0x20, R10)	|; R10 <= currentCell + 32
					MULC(R8,0x4,R11)	|;neighbours[R8]
					ADD(R9,R11,R11)
				ST(R10, 0x0, R11)	|; save top (R10)
				ADDC(R8,0x1,R8)		|; update n_valid_neighbours
			nobottom:

		|; while (n_valid_neighbours > 0)
		whilestart:
		BEQ(R8, whilestop)		|; if(n_valid_neighbours == 0) GOTO: whilestop
			
			RANDOM()				|; R0 <= rand()
			ANDC(R0,0xFFF,R0)		|; to avoid overflow during MOD
			MOD(R0,R8,R10)			|; 
				MULC(R8,0x4,R11)		|;neighbours[R8]
				ADD(R9,R11,R11)			
			LD(R11,0x0,R12)			|; load the selected neighbour index to R12

|; INSERT STRANGE SWAP HERE
		
			SUBC(R8, 0x1, R8)		|; n_valid_neighbours--
			
|; INSERT VISITED BITMAP MODIFICATION HERE
			
|; INSERTCONNECT CALL HERE

|; INSERT PERFECT_MAZE RECURSIVE CALL HERE
		
		BEQ(R31, whilestart)
		whilestop:
	|; This is an example of connect function call
	|; connect ( maze, source, destination, number of columns )
	|; Source cell, Destination cell, Number of Columns
	|; for horizontal : R3 = R2 +-1
	|; for vertical : R3 = R2 +-32
		HALT()
		ADDC(R5, 1, R16)	|; RC <- <RA> + C
		PUSH(R3)	|;nb_cols
		PUSH(R16)	|;destination	
		PUSH(R5)	|;source
		PUSH(R1)	|;maze
		CALL(connect)


	|; exit operations
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