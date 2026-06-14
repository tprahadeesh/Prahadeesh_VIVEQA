`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.06.2026 23:38:38
// Design Name: 
// Module Name: Decoder2_4
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


module Decoder2_4(
    input [1:0]a,
    output [3:0]b
    );
    assign b[0] = ~a[0] & ~a[1];
    assign b[1] = a[0] & ~a[1];
    assign b[2] = ~a[0] & a[1];
    assign b[3] = a[0] & a[1];
    
endmodule
