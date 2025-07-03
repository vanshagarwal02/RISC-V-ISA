module control_unit (
    input  [6:0] opcode,
    output       RegWrite,
    output       MemtoReg,
    output       MemRead,
    output       MemWrite,
    output       Branch,
    output       ALUSrc,
    output [1:0] ALUOp
);

  reg reg_write_r;
  reg mem_to_reg_r;
  reg mem_read_r;
  reg mem_write_r;
  reg branch_r;
  reg alu_src_r;
  reg [1:0] alu_op_r;

  assign RegWrite = reg_write_r;
  assign MemtoReg = mem_to_reg_r;
  assign MemRead  = mem_read_r;
  assign MemWrite = mem_write_r;
  assign Branch   = branch_r;
  assign ALUSrc   = alu_src_r;
  assign ALUOp    = alu_op_r;

  // Use AND gates to detect instructions:
  wire is_rtype = (~opcode[6]) &  opcode[5] &  opcode[4] & (~opcode[3]) &
                  (~opcode[2]) &  opcode[1] &  opcode[0];

  // ld: 0000011 -> bit6=0,5=0,4=0,3=0,2=0,1=1,0=1
  wire is_ld    = (~opcode[6]) & (~opcode[5]) & (~opcode[4]) & (~opcode[3]) &
                                (~opcode[2]) &  opcode[1] &  opcode[0];

  // sd: 0100011 -> bit6=0,5=1,4=0,3=0,2=0,1=1,0=1
  wire is_sd    = (~opcode[6]) &  opcode[5] & (~opcode[4]) & (~opcode[3]) &
                                (~opcode[2]) &  opcode[1] &  opcode[0];

  // beq: 1100011 -> bit6=1,5=1,4=0,3=0,2=0,1=1,0=1
  wire is_beq   =  opcode[6] &  opcode[5] & (~opcode[4]) & (~opcode[3]) &
                                (~opcode[2]) &  opcode[1] &  opcode[0];

  always @(*) begin
    // Default signal assignments
    reg_write_r  = 0;
    mem_to_reg_r = 0;
    mem_read_r   = 0;
    mem_write_r  = 0;
    branch_r     = 0;
    alu_src_r    = 0;
    alu_op_r     = 2'b00;

    // Assign control signals using AND-based instruction detection
    reg_write_r  = is_rtype | is_ld;
    alu_src_r    = is_ld | is_sd;
    mem_to_reg_r = is_ld;
    mem_read_r   = is_ld;
    mem_write_r  = is_sd;
    branch_r     = is_beq;

    // Set ALUOp without using if-else or ternary operators:
    // For R-type instructions, alu_op_r should be 2'b10; for branch, 2'b01; otherwise, 2'b00.
    alu_op_r[1]  = is_rtype;
    alu_op_r[0]  = is_beq;
  end
endmodule
