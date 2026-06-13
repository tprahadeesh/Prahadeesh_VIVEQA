`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10.06.2026 00:42:44
// Design Name: 
// Module Name: FAadder_tb
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
    reg a,b,cin;
    wire sum, cout;
   integer i;
    adder1bit dut(a,b,cin,sum,cout);
    initial begin
        for (i=0;i<8;i=i+1) begin
            #10;
            {a,b,cin} = i;
        end 
        #10
        $finish;
    end
        
endmodule
