|; constants
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

.macro MODC(Ra, c, Rc) DIVC(Ra, c, Rc) MULC(Rc, c, Rc) SUB(Ra, Rc, Rc)

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
connect:
PUSH(LP)
PUSH(BP)
|; save les registre que l'on va utiliser



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
|;R6 	-> 
|;R7 	->
|;R8 	->
|;R9 	->
|;R10	->
|;R11	-> tmp
|;R12	-> tmp
|;R13	-> tmp
|;----------
perfect_maze:

|;need function stuff

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
