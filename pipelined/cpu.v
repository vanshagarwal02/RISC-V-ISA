module mux2to1 (
    input  [63:0] in0,
    input  [63:0] in1,
    input         sel,
    output [63:0] out
);
  assign out = sel ? in1 : in0;
endmodule


module cpu_top (
    input clk,
    input reset
);

  //=================================================
  // Wire and Register Declarations
  //=================================================
  // Program Counter
  reg  [63:0] pc;
  wire [63:0] pc_next, pc_plus1;

  // Instruction Memory
  wire [31:0] instruction;
  wire if_id_WriteEnable, pc_WriteEnable;

  // IF/ID Pipeline Register
  wire [63:0] IF_ID_PC;  // Original PC from instruction fetch
  wire [31:0] IF_ID_instruction;

  // ID Stage Signals
  wire RegWrite_ID, MemtoReg_ID, MemRead_ID, MemWrite_ID, ALUSrc_ID, Branch_ID;
  wire [1:0] ALUOp_ID;
  wire [3:0] ALUControl_ID;
  wire [63:0] read_data1_ID, read_data2_ID, imm_out_ID;
  wire [4:0]  rs1_ID, rs2_ID, rd_ID;

  // ID/EX Pipeline Register Signals
  wire RegWrite_EX, MemtoReg_EX, MemRead_EX, MemWrite_EX, ALUSrc_EX, Branch_EX;
  wire [1:0] ALUOp_EX;
  wire [3:0] ALUControl_EX;
  wire [63:0] read_data1_EX, read_data2_EX, imm_out_EX;
  wire [4:0] rs1_EX, rs2_EX, rd_EX;
  wire [63:0] ID_EX_PC;  // PC passed to EX stage

  // EX Stage Signals
  wire [63:0] alu_in2;
  wire        alu_zero;
  wire [63:0] ALUResult_EX;
  wire branch_taken_EX;
  
  // Forwarding wires
  wire [63:0] forwardA_data;
  wire [63:0] forwardB_data;

  // EX/MEM Pipeline Register Signals
  wire RegWrite_MEM, MemtoReg_MEM, MemRead_MEM, MemWrite_MEM, Branch_MEM;
  wire [63:0] actual_target_EX;
  wire [63:0] actual_target_MEM;
  wire [63:0] ALUResult_MEM;
  wire [63:0] write_data_MEM;
  wire [4:0]  rd_MEM;
  wire [63:0] EX_MEM_PC;
  wire        branch_taken_MEM;

  // MEM Stage Signals
  wire [63:0] mem_read_data_MEM;

  // MEM/WB Pipeline Register Signals
  wire RegWrite_WB, MemtoReg_WB;
  wire [63:0] ALUResult_WB, mem_read_data_WB;
  wire [4:0]  rd_WB;
  wire [63:0] write_data_WB;

  // Hazard detection and forwarding
  wire Stall;
  wire [1:0] ForwardA;
  wire [1:0] ForwardB;

  // Branch Prediction Signals
  wire prediction_valid;
  wire misprediction;
  reg  flush;

  // Target address calculation
  wire [63:0] target_addr;

  //=================================================
  // Instruction Fetch (IF) Stage
  //=================================================
  // PC plus one computation
  adder_pc adder_pc_inst1 (
    .A      (pc),
    .B      (64'b1),
    .result (pc_plus1)
  );
  
  // Misprediction branch taken flag
  assign branch_taken_EX = Branch_EX && alu_zero;
  
  // Actual target calculation for branch misprediction
  adder_pc adder_pc_inst2 (
    .A      (ID_EX_PC),
    .B      (imm_out_EX),
    .result (actual_target_EX)
  );
  
  // PC selection using branch prediction
  mux2to1 mux_pc (
    .in0 (pc_plus1),
    .in1 (actual_target_MEM),
    .sel (branch_taken_MEM),
    .out (pc_next)
  );
  
  always @(posedge clk or posedge reset) begin
    if (reset)
      pc <= 64'b0;
    else if (pc_WriteEnable)
      pc <= pc_next;
  end
  
  instruction_memory imem (
    .addr        (pc),
    .instruction (instruction)
  );
  
  //=================================================
  // IF/ID Pipeline Register
  //=================================================
  IF_ID_Reg if_id_reg (
    .clk               (clk),
    .reset             (reset),
    .stall             (Stall),
    .flush             (flush),
    .if_id_WriteEnable (if_id_WriteEnable),
    .PC                (pc),           // Original PC
    .instruction       (instruction),
    .IF_ID_PC         (IF_ID_PC),
    .IF_ID_instruction(IF_ID_instruction)
  );
  
  //=================================================
  // Instruction Decode (ID) Stage
  //=================================================
  control_unit ctrl (
    .opcode    (IF_ID_instruction[6:0]),
    .RegWrite  (RegWrite_ID),
    .MemtoReg  (MemtoReg_ID),
    .MemRead   (MemRead_ID),
    .MemWrite  (MemWrite_ID),
    .Branch    (Branch_ID),
    .ALUSrc    (ALUSrc_ID),
    .ALUOp     (ALUOp_ID)
  );
  
  register_file rf (
    .clk        (clk),
    .reset      (reset),
    .RegWrite   (RegWrite_WB),
    .rs1        (IF_ID_instruction[19:15]),
    .rs2        (IF_ID_instruction[24:20]),
    .rd         (rd_WB),
    .write_data (write_data_WB),
    .read_data1 (read_data1_ID),
    .read_data2 (read_data2_ID)
  );
  
  immediate_gen immgen (
    .instruction (IF_ID_instruction),
    .imm_out     (imm_out_ID)
  );
  
  // Compute target address (PC + Imm)
  adder_pc adder_pc_inst3 (
    .A      (IF_ID_PC),
    .B      (imm_out_ID),
    .result (target_addr)
  );
  
  alu_control alu_ctrl (
    .ALUOp     (ALUOp_ID),
    .func3     (IF_ID_instruction[14:12]),
    .func7_5   (IF_ID_instruction[30]),
    .ALUControl(ALUControl_ID)
  );
  
  //=================================================
  // ID/EX Pipeline Register
  //=================================================
  ID_EX_Reg id_ex_reg (
    .clk           (clk),
    .reset         (reset),
    .flush         (flush),
    .stall         (Stall),
    // Control Signals
    .RegWrite_ID   (RegWrite_ID),
    .MemtoReg_ID   (MemtoReg_ID),
    .MemRead_ID    (MemRead_ID),
    .MemWrite_ID   (MemWrite_ID),
    .ALUSrc_ID     (ALUSrc_ID),
    .Branch_ID     (Branch_ID),
    .ALUOp_ID      (ALUOp_ID),
    .ALUControl_ID (ALUControl_ID),
    // Data signals
    .read_data1_ID (read_data1_ID),
    .read_data2_ID (read_data2_ID),
    .imm_out_ID    (imm_out_ID),
    .rs1_ID        (IF_ID_instruction[19:15]),
    .rs2_ID        (IF_ID_instruction[24:20]),
    .rd_ID         (IF_ID_instruction[11:7]),
    .PC_ID         (IF_ID_PC),
    // Outputs
    .RegWrite_EX   (RegWrite_EX),
    .MemtoReg_EX   (MemtoReg_EX),
    .MemRead_EX    (MemRead_EX),
    .MemWrite_EX   (MemWrite_EX),
    .ALUSrc_EX     (ALUSrc_EX),
    .Branch_EX     (Branch_EX),
    .ALUOp_EX      (ALUOp_EX),
    .ALUControl_EX (ALUControl_EX),
    .read_data1_EX (read_data1_EX),
    .read_data2_EX (read_data2_EX),
    .imm_out_EX    (imm_out_EX),
    .rs1_EX        (rs1_EX),
    .rs2_EX        (rs2_EX),
    .rd_EX         (rd_EX),
    .PC_EX         (ID_EX_PC)
  );
  
  //=================================================
  // Execute (EX) Stage
  //=================================================
  // Forwarding multiplexers
  assign forwardA_data = (ForwardA == 2'b10) ? ALUResult_MEM :
                           (ForwardA == 2'b01) ? write_data_WB : read_data1_EX;
  
  assign forwardB_data = (ForwardB == 2'b10) ? ALUResult_MEM :
                           (ForwardB == 2'b01) ? write_data_WB : read_data2_EX;
  
  // Select between forwarded data and immediate value for ALU's second input
  mux2to1 alu_in2_mux (
    .in0 (forwardB_data),
    .in1 (imm_out_EX),
    .sel (ALUSrc_EX),
    .out (alu_in2)
  );
  
  alu my_alu (
    .A          (forwardA_data),
    .B          (alu_in2),
    .ALUControl (ALUControl_EX),
    .ALUResult  (ALUResult_EX),
    .Zero       (alu_zero)
  );
  
  //=================================================
  // EX/MEM Pipeline Register
  //=================================================
  EX_MEM_Reg ex_mem_reg (
    .clk              (clk),
    .reset            (reset),
    .flush            (flush),
    // Control Signals
    .RegWrite_EX      (RegWrite_EX),
    .MemtoReg_EX      (MemtoReg_EX),
    .MemRead_EX       (MemRead_EX),
    .MemWrite_EX      (MemWrite_EX),
    .Branch_EX        (Branch_EX),
    .actual_target_EX (actual_target_EX),
    // Data signals
    .ALUResult_EX     (ALUResult_EX),
    .write_data_EX    (forwardB_data),
    .rd_EX            (rd_EX),
    .PC_EX            (ID_EX_PC),
    .branch_taken_EX  (branch_taken_EX),
    // Outputs
    .RegWrite_MEM     (RegWrite_MEM),
    .MemtoReg_MEM     (MemtoReg_MEM),
    .MemRead_MEM      (MemRead_MEM),
    .MemWrite_MEM     (MemWrite_MEM),
    .Branch_MEM       (Branch_MEM),
    .actual_target_MEM(actual_target_MEM),
    .ALUResult_MEM    (ALUResult_MEM),
    .write_data_MEM   (write_data_MEM),
    .rd_MEM           (rd_MEM),
    .PC_MEM           (EX_MEM_PC),
    .branch_taken_MEM (branch_taken_MEM)
  );
  
  //=================================================
  // Memory (MEM) Stage
  //=================================================
  data_memory dmem (
    .clk        (clk),
    .MemRead    (MemRead_MEM),
    .MemWrite   (MemWrite_MEM),
    .addr       (ALUResult_MEM),
    .write_data (write_data_MEM),
    .read_data  (mem_read_data_MEM)
  );
  
  //=================================================
  // MEM/WB Pipeline Register
  //=================================================
  MEM_WB_Reg mem_wb_reg (
    .clk             (clk),
    .reset           (reset),
    // Control Signals
    .RegWrite_MEM    (RegWrite_MEM),
    .MemtoReg_MEM    (MemtoReg_MEM),
    // Data signals
    .ALUResult_MEM   (ALUResult_MEM),
    .mem_read_data_MEM(mem_read_data_MEM),
    .rd_MEM          (rd_MEM),
    // Outputs
    .RegWrite_WB     (RegWrite_WB),
    .MemtoReg_WB     (MemtoReg_WB),
    .ALUResult_WB    (ALUResult_WB),
    .mem_read_data_WB(mem_read_data_WB),
    .rd_WB           (rd_WB)
  );
  
  //=================================================
  // Write Back (WB) Stage
  //=================================================
  mux2to1 wb_mux (
    .in0 (ALUResult_WB),
    .in1 (mem_read_data_WB),
    .sel (MemtoReg_WB),
    .out (write_data_WB)
  );
  
  //=================================================
  // Hazard Detection Unit
  //=================================================
  HazardDetectionUnit hdu (
    .ID_EX_MemRead  (MemRead_EX),
    .ID_EX_rd       (rd_EX),
    .IF_ID_rs1      (IF_ID_instruction[19:15]),
    .IF_ID_rs2      (IF_ID_instruction[24:20]),
    .stall          (Stall),
    .if_id_WriteEnable(if_id_WriteEnable),
    .pc_WriteEnable (pc_WriteEnable)
  );
  
  //=================================================
  // Forwarding Unit
  //=================================================
  ForwardingUnit fu (
    .ID_EX_rs1     (rs1_EX),
    .ID_EX_rs2     (rs2_EX),
    .EX_MEM_rd     (rd_MEM),
    .MEM_WB_rd     (rd_WB),
    .EX_MEM_RegWrite(RegWrite_MEM),
    .MEM_WB_RegWrite(RegWrite_WB),
    .ForwardA      (ForwardA),
    .ForwardB      (ForwardB)
  );
  
  //=================================================
  // Control: Branch flush logic
  //=================================================
  always @(*) begin
    flush = 0;
    if (branch_taken_MEM)
      flush = 1;
  end

endmodule
