module full_adder (
    input  a,
    input  b,
    input  c_in,
    output sum,
    output c_out
);
  wire w1, w2, w3;

  xor (sum, a, b, c_in);
  and (w1, a, b);
  and (w2, a, c_in);
  and (w3, b, c_in);
  or (c_out, w1, w2, w3);
endmodule

module adder_64 (
    input  [63:0] A,
    input  [63:0] B,
    output [63:0] result,
    // output        cout,
    output        zero
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

  // assign cout = carry_out;
  assign zero = 1'b0;
endmodule

module sub_64 (
    input [63:0] A,
    input [63:0] B,
    output [63:0] result,
    output zero
);
  wire [63:0] carry;
  wire [63:0] B_inv;
  wire        carry_out;

  // Invert B for two's complement subtraction
  genvar i;
  generate
    for (i = 0; i < 64; i = i + 1) begin : invB
      not u_not (B_inv[i], B[i]);
    end
  endgenerate

  assign carry[0] = 1'b1;

  genvar j;
  generate
    for (j = 0; j < 64; j = j + 1) begin : adders
      if (j == 63) begin
        full_adder u_fa (
            .a(A[j]),
            .b(B_inv[j]),
            .c_in(carry[j]),
            .sum(result[j]),
            .c_out(carry_out)
        );
      end else begin
        full_adder u_fa (
            .a(A[j]),
            .b(B_inv[j]),
            .c_in(carry[j]),
            .sum(result[j]),
            .c_out(carry[j+1])
        );
      end
    end
  endgenerate

  assign zero = (result == 64'b0) ? 1'b1 : 1'b0;
endmodule

module and_64 (
    input  [63:0] A,
    input  [63:0] B,
    output [63:0] result,
    output        zero
);
  genvar i;
  generate
    for (i = 0; i < 64; i = i + 1) begin
      and (result[i], A[i], B[i]);
    end
  endgenerate

  assign zero = 1'b0;
endmodule

module or_64 (
    input  [63:0] A,
    input  [63:0] B,
    output [63:0] result,
    output        zero
);
  genvar i;
  generate
    for (i = 0; i < 64; i = i + 1) begin
      or (result[i], A[i], B[i]);
    end
  endgenerate

  assign zero = 1'b0;
endmodule

module mux_2x1 (
    input  d0,
    input  d1,
    input  sel,
    output y
);
  wire n_sel, t0, t1;

  not u_not (n_sel, sel);
  and u_and0 (t0, d0, n_sel);
  and u_and1 (t1, d1, sel);
  or u_or_final (y, t0, t1);
endmodule


module alu (
    input [3:0] ALUControl,
    input [63:0] A,
    input [63:0] B,
    output [63:0] ALUResult,
    output Zero
);

  wire [63:0] add_result, sub_result, and_result, or_result;
  wire and_zero, or_zero, add_zero, sub_zero;

  adder_64 u_adder (
      .A(A),
      .B(B),
      .result(add_result),
      .zero(add_zero)
  );

  sub_64 u_sub (
      .A(A),
      .B(B),
      .result(sub_result),
      .zero(sub_zero)
  );

  and_64 u_and (
      .A(A),
      .B(B),
      .result(and_result),
      .zero(and_zero)
  );

  or_64 u_or (
      .A(A),
      .B(B),
      .result(or_result),
      .zero(or_zero)
  );

  wire sel_and, sel_or, sel_add, sel_sub;
  wire n_ALUControl3, n_ALUControl2, n_ALUControl1, n_ALUControl0;

  not u_not3 (n_ALUControl3, ALUControl[3]);
  not u_not2 (n_ALUControl2, ALUControl[2]);
  not u_not1 (n_ALUControl1, ALUControl[1]);
  not u_not0 (n_ALUControl0, ALUControl[0]);

  and u_sel_and (
      sel_and, n_ALUControl3, n_ALUControl2, n_ALUControl1, n_ALUControl0
  );  // 0000 : AND
  and u_sel_or (sel_or, n_ALUControl3, n_ALUControl2, n_ALUControl1, ALUControl[0]);  // 0001 : OR
  and u_sel_add (
      sel_add, n_ALUControl3, n_ALUControl2, ALUControl[1], n_ALUControl0
  );  // 0010 : ADD
  and u_sel_sub (
      sel_sub, n_ALUControl3, ALUControl[2], ALUControl[1], n_ALUControl0
  );  // 0110 : SUB

  // Structural 4-to-1 mux for the 64-bit result using gate-level AND and OR
  genvar i;
  generate
    for (i = 0; i < 64; i = i + 1) begin : mux_result_bits
      wire and_out, or_out, add_out, sub_out;
      and u_and_bit (and_out, and_result[i], sel_and);
      and u_or_bit (or_out, or_result[i], sel_or);
      and u_add_bit (add_out, add_result[i], sel_add);
      and u_sub_bit (sub_out, sub_result[i], sel_sub);

      // Combine the four signals using OR gates
      or u_or_final (ALUResult[i], add_out, sub_out, and_out, or_out);
    end
  endgenerate

  // Structural selection for the single-bit zero output
  wire zero_and, zero_or, zero_add, zero_sub;
  and u_and_zero (zero_and, and_zero, sel_and);
  and u_or_zero (zero_or, or_zero, sel_or);
  and u_add_zero (zero_add, add_zero, sel_add);
  and u_sub_zero (zero_sub, sub_zero, sel_sub);
  // wire temp_zero;
  // or u_zero_temp (temp_zero, zero_and, zero_or);
  or u_zero_final (Zero, zero_and, zero_or, zero_add, zero_sub);


endmodule
