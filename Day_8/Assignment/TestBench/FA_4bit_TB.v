`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11.06.2026 23:14:40
// Design Name: 
// Module Name: FA_4bit_TB
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


module FAadder_tb();
    reg [3:0]a;
    reg [3:0]b;
    reg cin;
    wire [3:0]sum;
    wire cout;
   integer i;
    rippleCarry_4bit dut(a,b,cin,sum,cout);
    initial begin
        for (i=0;i<500;i=i+1) begin
            #10;
            {a,b,cin} = i;
        end 
        #10
        $finish;
    end
        
endmodule
