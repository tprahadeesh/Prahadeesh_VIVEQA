`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.06.2026 11:06:56
// Design Name: 
// Module Name: counter
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


module counter(
    input clk,
    input rst,
    input ud,
    input ld,
    input [3:0]load,
    output reg [3:0]count
    );
    always @(posedge clk) begin
        if (rst) begin
            count <= 0;
        end
        else if (ld ==1) begin
            count <= load;
        end
        else begin
            if (ud) count <= count +1;
            else if (~ud) count <= count -1;
        end
     end
endmodule