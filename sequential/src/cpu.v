

module cpu_top (
    input clk,
    input reset
);

  //=========================
  // Program Counter (PC)
  //=========================
  reg [63:0] pc;

  always @(posedge clk or posedge reset) begin
    if (reset) pc <= 64'b0;
    else pc <= pc_next;
  end

  //=========================
  // Wires for connections
  //=========================
  wire [31:0] instruction;
  wire [6:0] opcode = instruction[6:0];
  wire [4:0] rd = instruction[11:7];
  wire [2:0] func3 = instruction[14:12];
  wire [4:0] rs1 = instruction[19:15];
  wire [4:0] rs2 = instruction[24:20];
  wire [6:0] func7 = instruction[31:25];
  wire func7_5 = func7[5];  // often used for sub vs add

  // Control signals
  wire RegWrite;
  wire MemtoReg;
  wire MemRead;
  wire MemWrite;
  wire Branch;
  wire ALUSrc;
  wire [1:0] ALUOp;

  // ALU control
  wire [3:0] ALUControl;

  // Register file outputs
  wire [63:0] reg_data1;
  wire [63:0] reg_data2;

  // Immediate
  wire [63:0] imm_out;

  // ALU inputs/outputs
  wire [63:0] alu_in2;
  wire [63:0] alu_result;
  wire alu_zero;

  // Data memory
  wire [63:0] mem_read_data;

  // Next PC
  wire [63:0] pc_plus_4;
  wire [63:0] pc_branch;
  wire branch_taken;
  reg [63:0] pc_next;

  //=========================
  // Instruction Memory
  //=========================
  instruction_memory imem (
      .addr(pc),
      .instruction(instruction)
  );

  //=========================
  // Control Unit
  //=========================
  control_unit ctrl (
      .opcode(opcode),
      .RegWrite(RegWrite),
      .MemtoReg(MemtoReg),
      .MemRead(MemRead),
      .MemWrite(MemWrite),
      .Branch(Branch),
      .ALUSrc(ALUSrc),
      .ALUOp(ALUOp)
  );

  //=========================
  // ALU Control
  //=========================
  alu_control alu_ctrl (
      .ALUOp(ALUOp),
      .func3(func3),
      .func7_5(func7_5),
      .ALUControl(ALUControl)
  );

  //=========================
  // Register File
  //=========================
  register_file rf (
      .clk(clk),
      .reset(reset),
      .RegWrite(RegWrite),
      .rs1(rs1),
      .rs2(rs2),
      .rd(rd),
      .write_data((MemtoReg) ? mem_read_data : alu_result),
      .read_data1(reg_data1),
      .read_data2(reg_data2)
  );
  wire [63:0] display_output;
 
  //=========================
  // Immediate Generation
  //=========================
  immediate_gen immgen (
      .instruction(instruction),
      .imm_out(imm_out)
  );

  //=========================
  // ALU Input Mux
  //=========================
  assign alu_in2 = (ALUSrc) ? imm_out : reg_data2;

  //=========================
  // ALU (already implemented by you in alu2.v)
  //=========================
  alu my_alu (
      .A(reg_data1),
      .B(alu_in2),
      .ALUControl(ALUControl),
      .ALUResult(alu_result),
      .Zero(alu_zero)
  );

  //=========================
  // Data Memory
  //=========================
  data_memory dmem (
      .clk(clk),
      .MemRead(MemRead),
      .MemWrite(MemWrite),
      .addr(alu_result),
      .write_data(reg_data2),
      .read_data(mem_read_data)
  );

  //=========================

 
  assign pc_plus_4 = pc + 64'd1;

  // branch target = pc + sign-extended immediate
  assign pc_branch = pc + (imm_out);  // for beq, shift immediate left by 1 for branch target
  //   aspc_branch = pc_branch >> 2;
  assign branch_taken = Branch & alu_zero;

  always @(*) begin
    // Using gate-level logic with replicated and gates:
    pc_next <= ({64{branch_taken}} & pc_branch) | ({64{~branch_taken}} & pc_plus_4);
  end


endmodule
