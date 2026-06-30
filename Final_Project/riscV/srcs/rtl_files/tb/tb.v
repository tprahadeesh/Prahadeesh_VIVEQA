`timescale 1ns/1ps
module tb();
  reg clk = 0;
  reg reset_n = 0;
  wire [7:0] leds;
  fpga_top dut (.clk(clk), .reset_n(reset_n), .leds(leds));
  always #5 clk = ~clk;
  initial begin
    #100 reset_n = 1;
    #100000000;
    $display("Simulation finished.");
    $finish;
  end
  always @(posedge clk) begin
  if (dut.cpu_core.pc == 32'hC4) begin  // When reaching instruction 50
    $display("=== INSTRUCTION 50 ===");
    $display("Time=%0t", $time);
    $display("  x3(i)=%d  x6(j)=%d  x7(k)=%d  x5(addr)=%x",
      dut.cpu_core.Datapath_Unit.regFILE.x[3],
      dut.cpu_core.Datapath_Unit.regFILE.x[6],
      dut.cpu_core.Datapath_Unit.regFILE.x[7],
      dut.cpu_core.Datapath_Unit.regFILE.x[5]);
    $display("  Stall_F=%b Stall_D=%b Stall_E=%b",
      dut.cpu_core.Hazard_Unit.stall_F_n,
      dut.cpu_core.Hazard_Unit.stall_D_n,
      dut.cpu_core.Hazard_Unit.stall_E_n);
  end
end
  
  // Monitor memory writes
  always @(posedge clk) begin
    if (dut.cpu_core.dmem_WE)
      $display("Time=%0t: WRITE mem[%x] = %x", $time, dut.cpu_core.memAdrs, dut.cpu_core.memDataWD);
  end
endmodule
