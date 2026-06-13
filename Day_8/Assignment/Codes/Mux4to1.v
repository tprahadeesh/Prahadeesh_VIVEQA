`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11.06.2026 23:44:26
// Design Name: 
// Module Name: Mux4to1
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


module Mux4to1(
    input [3:0] a,
    input [1:0]sel,
    output out
);
    Mux2to1 m1(a[1:0],sel[0],x);
    Mux2to1 m2(a[3:2],sel[0],y);
    Mux2to1 m3({y,x},sel[1],out);
endmodule

module Mux2to1(
    input [1:0] a,
    input sel,
    output out
);
    assign out = sel ? a[1] : a[0];
    
endmodule
