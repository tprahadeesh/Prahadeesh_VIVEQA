`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.06.2026 23:48:48
// Design Name: 
// Module Name: Largest_number_TB
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


module Largest_number_TB();
    reg [1:0]x;
    wire [1:0]y;
    reg clk,rst;
    Largest_number dut(x, clk,rst,y);
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
        x = 0;
        #20;
        x=2;
        #10;
        x=1;
        #10;
        x=0;
        #10;
        x=3;
        #20;
        $finish;
    end  
endmodule
