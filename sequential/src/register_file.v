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

  reg [63:0] regs[31:0];

  integer i;

  // Initialize registers to 0 on reset
  always @(posedge reset or posedge clk) begin
    if (reset) begin
      for (i = 0; i < 32; i = i + 1) regs[i] <= 64'b0;
      regs[5'b10] <= {{62{1'b0}}, 2'b10};
      regs[5'b11] <= {{62{1'b0}}, 2'b11};
      //store 1765 in reg[3]
    end
  end

  // Write operation on rising edge of clk
  always @(posedge clk) begin
    if (RegWrite && (rd != 5'b0)) begin
      regs[rd] <= write_data;
    end
  end


  // Read operation for read_data1 using a mux implemented as a bit mask
  always @(*) begin
    // When rs1 is zero, (rs1 != 0) evaluates to 0 and the mask becomes 64'b0.
    // Otherwise, the mask is 64'b1, returning the stored register value.
    // read_data1 = regs[rs1];
    read_data1 = regs[rs1] & {64{(rs1 != 5'd0)}};
  end

  // Read operation for read_data2 using a mux implemented as a bit mask
  always @(*) begin
    // read_data2 = regs[rs2];
    read_data2 = regs[rs2] & {64{(rs2 != 5'd0)}};
  end



endmodule
