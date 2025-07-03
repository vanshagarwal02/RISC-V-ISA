
module data_memory (
    input             clk,
    input             MemRead,
    input             MemWrite,
    input      [63:0] addr,
    input      [63:0] write_data,
    output reg [63:0] read_data
);

  reg [63:0] mem[63:0];  // 64 entries of 64-bit data
  integer i;
  // read_data = 64'b0;
  initial begin
    for (i = 0; i < 64; i = i + 1) begin
      mem[i] = 64'b0;
    end
    // mem[10]=64'b1;
  end

  always @(posedge clk) begin
    if (MemWrite) begin
      mem[addr[63:0]] <= write_data;
    end
  end

  always @(*) begin
    read_data = 64'b0;
    if (MemRead) begin
      read_data = mem[addr[63:0]];
    end
  end


endmodule
