module IF_ID_Reg (
  input clk,
  input reset,
  input stall,
  input flush,
  input if_id_WriteEnable,
  input [63:0] PC,            // Next PC value
  input [31:0] instruction,   // Fetched instruction
  output reg [63:0] IF_ID_PC,
  output reg [31:0] IF_ID_instruction
);

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      IF_ID_PC          <= 64'b0;
      IF_ID_instruction <= 32'b0;
    end else if (if_id_WriteEnable) begin
      IF_ID_PC          <= PC;
      IF_ID_instruction <= instruction;
    end

    if (flush) begin
      IF_ID_instruction <= 32'b0;
    end
  end

endmodule
