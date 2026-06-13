`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.06.2026 00:58:45
// Design Name: 
// Module Name: sr_latch_TB
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


module sr_latch_TB();
    reg s,r;
    wire q,q_bar;
    SR_latch dut( s,r, q,q_bar);
    initial begin
        s=1;
        r=0;
        #5;
        
        s=0;
        r=0;
        #20
        s=1;
        #20
        s=0;
        #1
        r=1;
    end
endmodule
