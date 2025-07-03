module cpu_tb;

  // Inputs
  reg clk;
  reg reset;

  // Instantiate the CPU
  cpu_top uut (
      .clk  (clk),
      .reset(reset)
  );

  // Clock generation
  initial begin
    // #6;
    clk = 0;
    forever #5 clk = ~clk;  // 10ns period clock
  end

  // Initialize and dump waveforms
  initial begin
    // Create waveform file
    $dumpfile("cpu_dump.vcd");
    $dumpvars(0, cpu_tb);  // Dump all variables
    // reset = 0;
    // #5;
    // Initialize inputs
    reset = 1;
    #20;  // Wait for first clock edge (10ns)
    reset = 0;  // Release reset after 10ns
    #300;
    $finish;
  end

endmodule
