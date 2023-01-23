
`define op_r      6'b000000
`define op_branch 6'b000001
`define op_beq    6'b000100
`define op_bne    6'b000101
`define rt_bgez   5'b00001
`define op_bgtz   6'b000111
`define op_blez   6'b000110
`define rt_bltz   5'b00000
`define rt_bgezal 5'b10001
`define rt_bltzal 5'b10000

`define op_j      6'b000010
`define op_jal    6'b000011

`define op_lui    6'b001111
`define op_ori    6'b001101
`define op_addiu  6'b001001
`define op_slti   6'b001010
`define op_sltiu  6'b001011
`define op_addi   6'b001000
`define op_andi   6'b001100
`define op_xori   6'b001110

`define op_lb     6'b100000
`define op_lbu    6'b100100
`define op_lh     6'b100001
`define op_lhu    6'b100101
`define op_lw     6'b100011
`define op_sb     6'b101000
`define op_sh     6'b101001
`define op_sw     6'b101011

`define op_mtc0   11'b010000_00100
`define op_mfc0   11'b010000_00000
`define op_eret   32'b010000_1000_0000_0000_0000_0000_011000

`define f_add     6'b100000
`define f_addu    6'b100001
`define f_sub     6'b100010
`define f_subu    6'b100011
`define f_and     6'b100100
`define f_nor     6'b100111
`define f_xor     6'b100110
`define f_jalr    6'b001001
`define f_jr      6'b001000
`define f_or      6'b100101
`define f_sll     6'b000000
`define f_sllv    6'b000100
`define f_srav    6'b000111
`define f_sra     6'b000011
`define f_srlv    6'b000110
`define f_srl     6'b000010
`define f_slt     6'b101010
`define f_sltu    6'b101011
`define f_break   6'b001101
`define f_syscall 6'b001100

`define f_mfhi    6'b010000
`define f_mflo    6'b010010
`define f_mthi    6'b010001
`define f_mtlo    6'b010011
`define f_mult    6'b011000
`define f_multu   6'b011001
`define f_div     6'b011010
`define f_divu    6'b011011




// RegDst
`define grf_rt 2'b00
`define grf_rd 2'b01
`define grf_ra 2'b10

// Branch
`define npc_offset 2'b00
`define npc_index 2'b01
`define npc_ra 2'b10

// memtoreg
`define wd3_alu 3'b001
`define wd3_rd 3'b000
`define wd3_pc 3'b010
`define wd3_mdu 3'b011
`define wd3_cp0 3'b100

// ALUSrc
`define alu_rd2 2'b00
`define alu_imm 2'b01

// ALUControl
`define alu_ADD    5'd1
`define alu_ADDI   5'd2
`define alu_ADDU   5'd3
`define alu_ADDIU  5'd4
`define alu_SUB    5'd5
`define alu_SUBU   5'd6
`define alu_SLT    5'd7
`define alu_SLTI   5'd8
`define alu_SLTU   5'd9
`define alu_SLTIU  5'd10
`define alu_AND    5'd11
`define alu_ANDI   5'd12
`define alu_LUI    5'd13
`define alu_NOR    5'd14
`define alu_OR     5'd15
`define alu_ORI    5'd16
`define alu_XOR    5'd17
`define alu_XORI   5'd18
`define alu_SLL    5'd19
`define alu_SLLV   5'd20
`define alu_SRA    5'd21
`define alu_SRAV   5'd22
`define alu_SRL    5'd23
`define alu_SRLV   5'd24


 

`define e_fsel_pc8 2'b01
`define e_fsel_ext 2'b00

`define m_fsel_mdu 2'b10
`define m_fsel_pc8 2'b01
`define m_fsel_alu 2'b00

`define inf 100

`define cmp_beq     4'd1
`define cmp_bne     4'd2
`define cmp_bgez    4'd3
`define cmp_bgtz    4'd4
`define cmp_blez    4'd5
`define cmp_bltz    4'd6
`define cmp_bltzal  4'd7
`define cmp_bgezal  4'd8


`define mdu_mult 4'd1
`define mdu_multu 4'd2
`define mdu_div 4'd3
`define mdu_divu 4'd4
`define mdu_mfhi 4'd5
`define mdu_mflo 4'd6
`define mdu_mthi 4'd7
`define mdu_mtlo 4'd8