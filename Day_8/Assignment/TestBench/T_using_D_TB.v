`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.06.2026 19:36:13
// Design Name: 
// Module Name: T_using_D_TB
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


module T_using_D_TB();
    reg t,clk,rst;
    wire q,q_bar;
    T_using_D dut(t,clk,rst, q, q_bar);
    initial begin 
        clk = 0;
        forever begin 
            clk = ~ clk;
            #5;
        end
    end
    initial begin  
        rst = 1;
        t =0;
        #10 rst = 0;
        #10 t =0;
        #10 t=0;
        #10 t=1;
        #10 t =0;
        #10 t=0;
        #10 t=1;
        #20 $finish;
    end
    
endmodule
