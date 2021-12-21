`ifndef DEFINITIONS_INCLUDED
`define DEFINITIONS_INCLUDED

typedef logic [63:0] long_t;
typedef logic [31:0] int_t;
typedef logic [15:0] short_t;
typedef logic [7:0]  byte_t;

//the intiali valeu of pc
`define PC_INIT          32'h00003000
//the size of instruction memory(words)
`define IM_WORDS         1024
`define DM_WORDS         2048
//the bit mask of IM_WORDS
`define IM_WORDS_MASK    10'b1111111111
`define DM_WORDS_MASK    11'b11111111111
`define MEMORY_MASK      32'hfffffffc
`define INT_SIZE         32
`define HALF_INT_SIZE    16
`define ZERO32           32'h0
`define ZERO26           26'h0
`define ZERO16           16'h0
`define ONE16            16'hffff 
`define ENABLE           1'b1
`define DIS_ABLE         1'b0
`define REG_ZERO         5'b0
`define SHIFT_ZERO       5'b0
`define REGBIT           5
`define SHIFT_BIT        5

`define N_BYTE(i) ((i + 1) * 8 - 1):(i * 8)
`define N_HALF_WORD(i) ((i + 1) * 16 - 1):(i * 16)
`endif