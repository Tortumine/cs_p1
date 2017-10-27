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
|;TODO make macro for : swap, row_from_index, col_from_index


neighbours__:
	STORAGE(4)  |; 8 words saved for the visited bitmap

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
