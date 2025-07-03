module EX_MEM_Reg (
    input             clk,
    input             reset,
    input             flush,
    input             RegWrite_EX,
    input             MemtoReg_EX,
    input             MemRead_EX,
    input             MemWrite_EX,
    input             Branch_EX,
    input      [63:0] actual_target_EX,
    input      [63:0] ALUResult_EX,
    input      [63:0] write_data_EX,
    input      [ 4:0] rd_EX,
    input      [63:0] PC_EX,
    input             branch_taken_EX,
    output reg        RegWrite_MEM,
    output reg        MemtoReg_MEM,
    output reg        MemRead_MEM,
    output reg        MemWrite_MEM,
    output reg        Branch_MEM,
    output reg [63:0] ALUResult_MEM,
    output reg [63:0] actual_target_MEM,
    output reg [63:0] write_data_MEM,
    output reg [ 4:0] rd_MEM,
    output reg [63:0] PC_MEM,
    output reg        branch_taken_MEM
);

  always @(posedge clk or posedge reset) begin
    if (reset || flush) begin
      RegWrite_MEM      <= 0;
      MemtoReg_MEM      <= 0;
      MemRead_MEM       <= 0;
      MemWrite_MEM      <= 0;
      Branch_MEM        <= Branch_EX;
      actual_target_MEM <= actual_target_EX;
      ALUResult_MEM     <= 0;
      write_data_MEM    <= 0;
      rd_MEM            <= 0;
      PC_MEM            <= 0;
      branch_taken_MEM  <= branch_taken_EX;
    end else begin
      RegWrite_MEM      <= RegWrite_EX;
      MemtoReg_MEM      <= MemtoReg_EX;
      MemRead_MEM       <= MemRead_EX;
      MemWrite_MEM      <= MemWrite_EX;
      Branch_MEM        <= Branch_EX;
      actual_target_MEM <= actual_target_EX;
      ALUResult_MEM     <= ALUResult_EX;
      write_data_MEM    <= write_data_EX;
      rd_MEM            <= rd_EX;
      PC_MEM            <= PC_EX;
      branch_taken_MEM  <= branch_taken_EX;
    end
  end

endmodule
