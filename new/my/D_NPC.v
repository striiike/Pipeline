
`define npc_offset 2'b00
`define npc_index 2'b01
`define npc_ra 2'b10

module D_NPC (
    input         eret,
    input  [31:0] EPC,

    input  [ 1:0] sel,
    input  [31:0] pc,
    input         brCtrl,
    input  [31:0] imm16,
    input  [31:0] imm26,
    input  [31:0] ra,
    output [31:0] npc,
    output isNPC
);

    assign npc = (sel == `npc_offset && brCtrl) ? {imm16[29:0], 2'b00} + pc + 4 : 
                 (sel == `npc_index)            ? imm26 : 
                 (sel == `npc_ra)               ? ra : 
                                                pc + 8 ;
    assign isNPC = (sel != 2'b11);
endmodule
