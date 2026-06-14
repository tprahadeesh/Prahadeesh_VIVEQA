`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.06.2026 23:03:32
// Design Name: 
// Module Name: fsm_110_detector_TB
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


module fsm_110_detector_TB();
    reg x,clk,rst;
    wire y;
    fsm_110_detector dut(x,clk,rst,y);
    initial begin
        clk = 0;
        forever begin
            clk = ~clk;
            #5;
        end
    end
    initial begin 
        rst = 1;
        #15;
        rst =0;
        x = 1;
        #10;
        x=1;
        #10;
        x=0;
        #10;
        x=1;
        #10;
        x=1;
        #10;
        x=1;
        #10;
        x=1;
        #10;
        x=0;
        #10;
        x=0;
        #20;
        $finish;
    end
        
endmodule
