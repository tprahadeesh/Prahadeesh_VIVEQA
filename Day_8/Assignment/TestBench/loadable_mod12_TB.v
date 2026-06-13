`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.06.2026 22:23:54
// Design Name: 
// Module Name: loadable_mod12_TB
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module upDown_tb();
  reg clk,rst;
  wire [3:0]count;
  reg ud,ld;
  reg [3:0] load;
 Loadable_Mod12 dut(clk,rst,ud,ld,load,count);
  initial begin
    clk = 1'b0;
    forever begin
      clk = ~clk;
      #5;
    end
  end
  initial begin
    rst =1;
    #10;
    rst =0;
    load = 5;
    #5 ud = 1;
    #300 ud = 0;
    #30 ld = 1;
    #15 ld =0;
    #30 rst = 1;
    #20 $finish;
  end
endmodule
