|; TODO :: ADD AS MUCH MACROS AS YOU CAN
|; TODO :: clean unnecessary CONSTANTS
|; TODO :: find a better name for the "STUFF" part
|; TODO :: Connect integration in the perfect maze function 428-440

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
	|; get 3 regs Ra Rb and Rtmp , switch Ra and Rb
	.macro SWITCH(Ra,Rb,Rtmp){
		MOVE(Ra, Rtmp)
		MOVE(Rb, Ra)
		MOVE(Rtmp,Rb)
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

|; cf C code
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
|;		dest_row -> R5					= dest / nb_cols
|;		row_offset -> R6				= dest_row * WORDS_PER_ROW
|;		source_col -> R7				= source % nb_cols
|;		word_offset_in_line -> R8		= source_col / CELLS_PER_WORD
|;		word_offset -> R9				= row_offset + word_offset_in_line
|;		byte_offset -> R10				= source_col % CELLS_PER_WORD
|;		----------
|;		TMP vars
|;		----------
|;		tmp1 -> R11
|;		tmp2 -> R12
|;		tmp3 -> R13
|;		tmp4 -> R14
|;		tmp5 -> R15		= pointer to the first word to edit

connect:
|; Saving local variables form the caller
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
	
	|; Load Parameters
	LD(BP, -12, R1) |;Get param Maze
	LD(BP, -16, R2) |;Get param source
	LD(BP, -20, R3)	|;Get param dest
	LD(BP, -24, R4) |;Get param nb_cols

	|; if(source > dest) -> swap
	CMPLT(R3, R2, R11)			|;check if R2<R3
	BEQ(R11, noswaplabel)		|; IF <R11>!=0 THEN PC <- LABEL
		SWITCH(R2,R3,R11)		|; switch R2 and R3
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
	
	MOVE(R31,r0) |; return 0x0
	MOVE(BP,SP)
	POP(BP)
	POP(LP)
	RTN()
	
	
|;----------
|;perfect_maze
|;----------
|;PARAMETERS
|;
|;
|;
|;
|;
|;REGISTER
|;R1 	-> Maze
|;R2 	-> Rows
|;R3 	-> Cols
|;R4 	-> Visited
|;R5 	-> CurrentCell
|;R6 	-> n_valid_neighbours
|;R7 	-> neighbours[4]
|;R8 	-> neighbours
|;R9 	-> random_neigh_index
|;R10	-> col/row
|;R11	-> tmp
|;R12	-> tmp
|;R13	-> tmp
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
.breakpoint
LD(BP, -12, R1) |;Get params Maze
LD(BP, -16, R2) |;Get params Rows
LD(BP, -20, R3)	|;Get Cols Params
LD(BP, -24, R4) |;Get Visited Params
LD(BP, -28, R5) |;Get CurrentCell Params

|; set current cell as visited
|; Set mask
MODC(R5, 32, R11) 	|;R11 <- current_cell%32
CMOVE(1, R12)
SHL(R12, R11, R11)	|;R11 <- (1 << Current_cell%32)
|;Get VisitedRegister
DIVC(R5, 32, R12)	|;R12 <- curr_cell / 32
ADD(R4, R12, R12)	|;R12 <- visited[curr_cell / 32]
LD(R12, 0, R13)		|;R13 <- &visited[curr_cell / 32]
OR(R13, R11, R13)	|;visited[curr_cell /32] |= (1 << curr_cell % 32)
ST(R13, 0, R12)		|;Save visited[curr_cell /32] |= (1 << curr_cell % 32)

|;neighbours
|;How manage that ?
|;valid neighbours static array and array size
CMOVE(neighbours__, R7)	|;int neighbours[4] 
CMOVE(0, R6)		|;n_valid_neighbours = 0; 

|;Check for left neighbour
|;int col = col_from_index(curr_cell, nb_cols);
|;index % nb_cols;
MOD(R5, R3, R10)	|;int col = index % nb_cols
|;if (col > 0)
CMPLEC(R10, 0, R11)	|;if (col <= 0)
BNE(R11, noleft)	|;if R11 != 0 then col <= 0 then col !> 0
|;neighbours[n_valid_neighbours++] = curr_cell - 1;
MULC(R6, 4, R11)	|;n_Valid_neighbours * 4 -> determiner offset in memory
LD(R11, 0, R12)		|;Load Register
SUBC(R5, 1, R12)	|;loaded Register <- curr_cell -1
ST(R12, 0, R11)		|;save register
ADDC(R6, 1, R6)		|;n_valid_neighbours++
noleft:
|;check right neighbour
|;(col < nb_cols - 1)
SUBC(R3, 1, R11)	|;R11 <- nb_cols - 1
CMPLT(R10, R11, R11)	|;R11 <- if(col<nb_cols-1)
BEQ(R11, noright)	|;if !(col < nb_cols -1) go to label
|;neighbours[n_valid_neighbours++] = curr_cell + 1;
MULC(R6, 4, R11)	|;n_Valid_neighbours * 4 -> determiner offset in memory
			|; Add Register adresse + offset
LD(R11, 0, R12)		|;Load Register
ADDC(R5, 1, R12)	|;loaded Register <- curr_cell + 1
ST(R12, 0, R11)		|;save register
ADDC(R6, 1, R6)		|;n_valid_neighbours++
noright:
|;int row = row_from_index(curr_cell, nb_cols);
DIV(R5, R3, R10)	|;return index / nb_cols;
|;check top neighbour
|;if(row > 0) => !(row <= 0)
CMPLEC(R10, 0, R11)
BNE(R11, notop)
|;neighbours[n_valid_neighbours++] = curr_cell - nb_cols;
MULC(R6, 4, R11)	|;n_Valid_neighbours * 4 -> determiner offset in memory
LD(R11, 0, R12)		|;Load Register
SUB(R5, R3, R12)	|;loaded Register <- curr_cell - nb_cols
ST(R12, 0, R11)		|;save register
ADDC(R6, 1, R6)		|;n_valid_neighbours++
notop:
|;check bottom neighbour
|;if(row < nb_rows - 1)
SUBC(R2, 1, R11) 	|;R11 <- nb_rows - 1
CMPLT(R10, R11, R11)	|;R11 <- row < nb_rows - 1
BEQ(R11, nobottom)
|;neighbours[n_valid_neighbours++] = curr_cell + nb_cols;
MULC(R6, 4, R11)	|;n_Valid_neighbours * 4 -> determiner offset in memory
LD(R11, 0, R12)		|;Load Register
ADD(R5, R3, R12)	|;loaded Register <- curr_cell + nb_cols
ST(R12, 0, R11)		|;save register
ADDC(R6, 1, R6)		|;n_valid_neighbours++
nobottom:
|;explore valid neighbours
while:
|;(n_valid_neighbours > 0)
CMPLEC(R6, 0, R11)
BNE(R11, endwhile)

|;int random_neigh_index = rand() % n_valid_neighbours;
RANDOM()
MOD(R0, R6, R9) 	|;
|;int neighbour = neighbours[random_neigh_index];
MULC(R9, 4, R11)	|;random_neigh_index * 4 -> determiner offset in memory
ADD(R7, R11, R11)	|;Add offset to adresse 
LD(R11, 0, R8)		|;R8 <- Neighbour
|;swap(neighbours + n_valid_neighbours - 1, neighbours + random_neigh_index);

|;n_valid_neighbours--;
SUBC(R6, 1, R6)
|;int visited_bit = (visited[neighbour / 32] >> (neighbour % 32)) & 1; 
DIVC(R8, 32, R12)	|;R12 <- neighbours / 32
ADD(R4, R12, R12)	|;R12 <- visited[neighbours / 32]
LD(R12, 0, R13)		|;R13 <- &visited[neighbours / 32]
MODC(R8, 32, R11)	|;(neighbour % 32)
SRA(R13, R11, R11)	|;(visited[neighbour / 32] >> (neighbour % 32))
ANDC(R11, 1, R11)	|;visited_bit = (visited[neighbour / 32] >> (neighbour % 32)) & 1

|;if (visited_bit == 1)
|;continue;
CMPEQC(R11, 1, R11)
BNE(R11, while)
|;connect(maze, curr_cell, neighbour, nb_cols);

	|; This is an example of connect function call
	|; It requires 3 params
	|; Source cell, Destination cell, Number of Columns
	|; for horizontal : R3 = R2 +-1
	|; for vertical : R3 = R2 +-32
		CMOVE(0,R2) 
		CMOVE(32,R3)
		CMOVE(NB_COLS,R4)
		PUSH(R4)	|;nb_cols
		PUSH(R3)	|;source	
		PUSH(R2)	|;dest
		PUSH(R1)	|;maze
		CALL(connect)

|;perfect_maze(maze, nb_rows, nb_cols, visited, neighbour);
PUSH(R5) |; CurrentCell
PUSH(R4) |; Visited
PUSH(R3) |; Cols
PUSH(R2) |; Rows
PUSH(R1) |; Maze
CALL(perfect_maze)
DEALLOCATE(5)
BR(while)

endwhile:
|;TODO make return
ADDC(R31, 0xDEADCAFE, R13)	|;just test condition
