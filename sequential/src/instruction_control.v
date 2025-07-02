module instruction_memory (
    input  [63:0] addr,
    output [31:0] instruction
);

  // 64 words of 32-bit instructions, for example
  reg [31:0] mem[63:0];

  initial begin

    $readmemb("instructions.txt", mem);
  end

  assign instruction = mem[addr[63:0]];

endmodule
