module adder_pc (
    input  [63:0] A,
    input  [63:0] B,
    output [63:0] result
);
  wire [63:0] carry;
  wire        carry_out;

  assign carry[0] = 1'b0;

  genvar i;
  generate
    for (i = 0; i < 64; i = i + 1) begin
      if (i == 63) begin
        full_adder fa (
            .a(A[i]),
            .b(B[i]),
            .c_in(carry[i]),
            .sum(result[i]),
            .c_out(carry_out)
        );
      end else begin
        full_adder fa (
            .a(A[i]),
            .b(B[i]),
            .c_in(carry[i]),
            .sum(result[i]),
            .c_out(carry[i+1])
        );
      end
    end
  endgenerate


endmodule
