module MEM_WB_Reg (
    input             clk,
    input             reset,
    // Control signals from the MEM stage
    input             RegWrite_MEM,
    input             MemtoReg_MEM,
    input      [63:0] ALUResult_MEM,
    input      [63:0] mem_read_data_MEM,
    input      [ 4:0] rd_MEM,
    // Outputs to the WB stage
    output reg        RegWrite_WB,
    output reg        MemtoReg_WB,
    output reg [63:0] ALUResult_WB,
    output reg [63:0] mem_read_data_WB,
    output reg [ 4:0] rd_WB
);

  // Pipeline register update on clock edge or reset
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      RegWrite_WB      <= 1'b0;
      MemtoReg_WB      <= 1'b0;
      ALUResult_WB     <= 64'b0;
      mem_read_data_WB <= 64'b0;
      rd_WB            <= 5'b0;
    end else begin
      RegWrite_WB      <= RegWrite_MEM;
      MemtoReg_WB      <= MemtoReg_MEM;
      ALUResult_WB     <= ALUResult_MEM;
      mem_read_data_WB <= mem_read_data_MEM;
      rd_WB            <= rd_MEM;
    end
  end

endmodule
