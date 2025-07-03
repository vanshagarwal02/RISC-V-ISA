module ID_EX_Reg (
    input             clk,
    input             reset,
    input             flush,
    input             stall,
    // Control signals from ID stage
    input             RegWrite_ID,
    input             MemtoReg_ID,
    input             MemRead_ID,
    input             MemWrite_ID,
    input             ALUSrc_ID,
    input             Branch_ID,
    input      [ 1:0] ALUOp_ID,
    input      [ 3:0] ALUControl_ID,
    // Data signals from ID stage
    input      [63:0] read_data1_ID,
    input      [63:0] read_data2_ID,
    input      [63:0] imm_out_ID,
    input      [ 4:0] rs1_ID,
    input      [ 4:0] rs2_ID,
    input      [ 4:0] rd_ID,
    input      [63:0] PC_ID,          // Original PC from IF/ID
    // Outputs to EX stage
    output reg        RegWrite_EX,
    output reg        MemtoReg_EX,
    output reg        MemRead_EX,
    output reg        MemWrite_EX,
    output reg        ALUSrc_EX,
    output reg        Branch_EX,
    output reg [ 1:0] ALUOp_EX,
    output reg [ 3:0] ALUControl_EX,
    output reg [63:0] read_data1_EX,
    output reg [63:0] read_data2_EX,
    output reg [63:0] imm_out_EX,
    output reg [ 4:0] rs1_EX,
    output reg [ 4:0] rs2_EX,
    output reg [ 4:0] rd_EX,
    output reg [63:0] PC_EX
);

  // Synchronous block with asynchronous reset/flush
  always @(posedge clk or posedge reset) begin
    if (reset || flush) begin
      // Reset state: convert to NOP
      {RegWrite_EX, MemtoReg_EX, MemRead_EX, MemWrite_EX, ALUSrc_EX, Branch_EX} <= 6'b0;
      ALUOp_EX                                                                  <= 2'b0;
      ALUControl_EX                                                             <= 4'b0;
      read_data1_EX                                                             <= 64'b0;
      read_data2_EX                                                             <= 64'b0;
      imm_out_EX                                                                <= 64'b0;
      rs1_EX                                                                    <= 5'b0;
      rs2_EX                                                                    <= 5'b0;
      rd_EX                                                                     <= 5'b0;
      PC_EX                                                                     <= 64'b0;
    end else if (!stall) begin
      // Propagate signals from ID to EX stage
      RegWrite_EX   <= RegWrite_ID;
      MemtoReg_EX   <= MemtoReg_ID;
      MemRead_EX    <= MemRead_ID;
      MemWrite_EX   <= MemWrite_ID;
      ALUSrc_EX     <= ALUSrc_ID;
      Branch_EX     <= Branch_ID;
      ALUOp_EX      <= ALUOp_ID;
      ALUControl_EX <= ALUControl_ID;
      read_data1_EX <= read_data1_ID;
      read_data2_EX <= read_data2_ID;
      imm_out_EX    <= imm_out_ID;
      rs1_EX        <= rs1_ID;
      rs2_EX        <= rs2_ID;
      rd_EX         <= rd_ID;
      PC_EX         <= PC_ID;
    end else begin
      // Stall: keep data signals intact, disable control signals
      RegWrite_EX <= 1'b0;
      MemtoReg_EX <= 1'b0;
      MemRead_EX  <= 1'b0;
      MemWrite_EX <= 1'b0;
      ALUSrc_EX   <= 1'b0;
      Branch_EX   <= 1'b0;
      ALUOp_EX    <= 2'b0;
    end
  end

endmodule
