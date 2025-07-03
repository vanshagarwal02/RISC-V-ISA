module ForwardingUnit (
  input  [4:0] ID_EX_rs1,
  input  [4:0] ID_EX_rs2,
  input  [4:0] EX_MEM_rd,
  input  [4:0] MEM_WB_rd,
  input        EX_MEM_RegWrite,
  input        MEM_WB_RegWrite,
  output reg [1:0] ForwardA,
  output reg [1:0] ForwardB
);

  // Function: get_forward_control
  // Determines the forwarding mux control signal for a given source register.
  // A return value of 2’b10 indicates forwarding from the EX/MEM stage,
  // 2’b01 indicates forwarding from the MEM/WB stage,
  // and 2’b00 indicates no forwarding.
  function [1:0] get_forward_control;
    input [4:0] rs;             // Source register to check
    input [4:0] ex_mem_rd;      // Destination register from EX/MEM stage
    input       ex_mem_regwrite;// Write enable for EX/MEM stage
    input [4:0] mem_wb_rd;      // Destination register from MEM/WB stage
    input       mem_wb_regwrite;// Write enable for MEM/WB stage
    begin
      if (ex_mem_regwrite && (ex_mem_rd != 0) && (ex_mem_rd == rs))
        get_forward_control = 2'b10;
      else if (mem_wb_regwrite && (mem_wb_rd != 0) && (mem_wb_rd == rs))
        get_forward_control = 2'b01;
      else
        get_forward_control = 2'b00;
    end
  endfunction

  // Combinational logic for Forwarding Unit.
  always @(*) begin
    ForwardA = get_forward_control(ID_EX_rs1, EX_MEM_rd, EX_MEM_RegWrite,
                                   MEM_WB_rd, MEM_WB_RegWrite);
    ForwardB = get_forward_control(ID_EX_rs2, EX_MEM_rd, EX_MEM_RegWrite,
                                   MEM_WB_rd, MEM_WB_RegWrite);
  end

endmodule
