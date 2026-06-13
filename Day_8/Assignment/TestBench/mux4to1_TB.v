`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.06.2026 00:07:20
// Design Name: 
// Module Name: mux4to1_TB
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


module mux4to1_TB();
    reg [3:0]a;
    reg [1:0]sel;
    wire out;
    Mux4to1 dut(a,sel,out);
    initial begin
        a = 4'b1001;
        #5
        sel = 0;
        #5
        sel = 1;
        #5  
        sel = 2;
        #5
        sel = 3;
        #5;
    end    
    
endmodule
