// 4-to-1 multiplexer module using an always block
module mux4_4bit (
    input [3:0] in0,
    input [3:0] in1,
    input [3:0] in2,
    input [3:0] in3,
    input [1:0] sel,
    output reg [3:0] out
);
  always @(*) begin
    case (sel)
      2'b00:   out = in0;
      2'b01:   out = in1;
      2'b10:   out = in2;
      default: out = in3;
    endcase
  end
endmodule

// R-type decoder module using an always block
module r_type_decoder (
    input      [2:0] func3,
    input            func7_5,
    output reg [3:0] alu_control_out
);
  always @(*) begin
    case (func3)
      3'b000: begin
        if (func7_5) alu_control_out = 4'b0110;  // SUB
        else alu_control_out = 4'b0010;  // ADD
      end
      3'b111:  alu_control_out = 4'b0000;  // AND
      3'b110:  alu_control_out = 4'b0001;  // OR
      default: alu_control_out = 4'b1111;  // NOP/unsupported
    endcase
  end
endmodule

// Top-level ALU control module that instantiates the multiplexer and R-type decoder.
module alu_control (
    input      [1:0] ALUOp,
    input      [2:0] func3,
    input            func7_5,    // often bit 5 of func7 (the MSB), e.g. for SUB
    output reg [3:0] ALUControl
);

  // Constant control codes
  wire [3:0] ctrl_ld_sd = 4'b0010;  // ADD (for ld, sd)
  wire [3:0] ctrl_beq = 4'b0110;  // SUB (for beq)
  wire [3:0] ctrl_default = 4'b1111;  // default/unsupported

  // Wires to catch outputs from submodules
  wire [3:0] rtype_out;
  wire [3:0] mux_out;

  // Instantiation of the R-type decoder module
  r_type_decoder rtype_inst (
      .func3(func3),
      .func7_5(func7_5),
      .alu_control_out(rtype_out)
  );

  // Instantiation of the multiplexer module
  mux4_4bit mux_inst (
      .in0(ctrl_ld_sd),
      .in1(ctrl_beq),
      .in2(rtype_out),
      .in3(ctrl_default),
      .sel(ALUOp),
      .out(mux_out)
  );

  // Always block to assign the final ALU control signal
  always @(*) begin
    ALUControl = mux_out;
  end
endmodule
