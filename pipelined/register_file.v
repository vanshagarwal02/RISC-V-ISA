module register_file (
    input             clk,
    input             reset,
    input             RegWrite,
    input      [ 4:0] rs1,
    input      [ 4:0] rs2,
    input      [ 4:0] rd,
    input      [63:0] write_data,
    output reg [63:0] read_data1,
    output reg [63:0] read_data2
);

  // Register storage: 32 registers of 64 bits each
  reg [63:0] regs[0:31];
  integer i;

  // Reset and initialization process
  always @(posedge reset or posedge clk) begin : RESET_AND_INIT
    if (reset) begin
      // Initialize all registers to 0
      for (i = 0; i < 32; i = i + 1) begin
        regs[i] <= 64'b0;
      end

      // Specific register initializations
      regs[1] <= 64'b101;  // reg[1] = 5 (binary 101)
      regs[2] <= 64'b10;  // reg[2] = 10 (binary 1010)
      regs[3] <= 64'b11;  // reg[3] = 20 (binary 10100)
      regs[4] <= 64'b10;  // reg[4] = 2 (binary 10)
      // store 1765 in reg[?] if needed (comment available for future use)
    end
  end

  // Write operation process on the negative edge of clk
  always @(negedge clk) begin : WRITE_OPERATION
    if (RegWrite && (rd != 5'b0)) begin
      regs[rd] = write_data;
    end
  end

  // Read operation for rs1 using a multiplexer implemented as a bit mask
  always @(*) begin : READ_DATA1_BLOCK
    read_data1 = regs[rs1] & {64{(rs1 != 5'b0)}};
  end

  // Read operation for rs2 using a multiplexer implemented as a bit mask
  always @(*) begin : READ_DATA2_BLOCK
    read_data2 = regs[rs2] & {64{(rs2 != 5'b0)}};
  end

endmodule
