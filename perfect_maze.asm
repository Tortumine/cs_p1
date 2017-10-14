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




perfect_maze:

