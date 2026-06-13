`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11.06.2026 19:39:30
// Design Name: 
// Module Name: priority_encoder83
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


module priority_encoder83(
    input [7:0]in,
    output [2:0]out
);
    assign out[0] = ~in[6] & (~in[4]&~in[2]&in[1] | ~in[4]&in[3] | in[5]) | in[7];
    assign out[1] = ~in[5]&~in[4]&(in[2]|in[3]) | in[6] | in[7];
    assign out[2] = in[4] | in[5] | in[6] | in[7]; 
endmodule
