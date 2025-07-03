module HazardDetectionUnit (
    input  wire       ID_EX_MemRead,      // Is current instruction a load?
    input  wire [4:0] ID_EX_rd,           // Destination register of load
    input  wire [4:0] IF_ID_rs1,          // Source register 1 in the ID stage
    input  wire [4:0] IF_ID_rs2,          // Source register 2 in the ID stage
    output reg        stall,              // Stall the pipeline
    output reg        if_id_WriteEnable,
    output reg        pc_WriteEnable
);

  // Combinational logic for hazard detection
  always @(*) begin
    // Default assignments: pipeline enabled and no stall
    stall             = 1'b0;
    if_id_WriteEnable = 1'b1;
    pc_WriteEnable    = 1'b1;

    // If a load instruction is in the EX stage and there's a hazard,
    // stall the pipeline and disable writes.
    if (ID_EX_MemRead && ((ID_EX_rd == IF_ID_rs1) || (ID_EX_rd == IF_ID_rs2))) begin
      stall             = 1'b1;
      if_id_WriteEnable = 1'b0;
      pc_WriteEnable    = 1'b0;
    end
  end

endmodule
