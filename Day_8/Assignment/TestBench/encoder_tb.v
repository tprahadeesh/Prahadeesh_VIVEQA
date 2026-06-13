`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11.06.2026 19:54:52
// Design Name: 
// Module Name: encoder_tb
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


module encoder_tb();
    reg [7:0]in;
    wire [2:0]out;
    integer i;
    priority_encoder83 dut(in,out);
    initial begin 
        in =0;
        #5
        for (i=0;i<8;i=i+1) begin
            in[i] = 1'b1;
            #10
            in = 0;
            in[1] = 1'b1;
            in[0] = 1'b1;
        end
    end
endmodule
