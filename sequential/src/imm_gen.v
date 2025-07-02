module immediate_gen (
    input [31:0] instruction,
    output reg [63:0] imm_out
);

  // Decode opcodes using bit logic.
  wire ld;
  assign ld = (~instruction[6] & ~instruction[5] & ~instruction[4] &
               ~instruction[3] & ~instruction[2] & instruction[1] & instruction[0]);

  wire sd;
  assign sd = (~instruction[6] & instruction[5] & ~instruction[4] &
               ~instruction[3] & ~instruction[2] & instruction[1] & instruction[0]);

  wire beq;
  assign beq = (instruction[6] & instruction[5] & ~instruction[4] &
                ~instruction[3] & ~instruction[2] & instruction[1] & instruction[0]);

  // Immediate generation.
  wire [63:0] imm_ld;
  assign imm_ld = {{52{instruction[31]}}, instruction[31:20]};

  wire [63:0] imm_sd;
  assign imm_sd = {{52{instruction[31]}}, instruction[31:25], instruction[11:7]};

  wire [63:0] imm_beq;
  assign imm_beq = {
    {52{instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8]

  };

  integer i;
  always @(*) begin
    if (ld) begin
      for (i = 0; i < 64; i = i + 1) imm_out[i] = imm_ld[i];
    end else if (sd) begin
      for (i = 0; i < 64; i = i + 1) imm_out[i] = imm_sd[i];
    end else if (beq) begin
      for (i = 0; i < 64; i = i + 1) imm_out[i] = imm_beq[i];
    end else begin
      for (i = 0; i < 64; i = i + 1) imm_out[i] = 1'b0;
    end
  end

endmodule
