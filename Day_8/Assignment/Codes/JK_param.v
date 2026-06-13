`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.06.2026 01:27:20
// Design Name: 
// Module Name: JK_param
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


module JK_param(input j,k,clk, output reg q,q_bar);

    parameter hold = 2'b00,
              toggle = 2'b01,
              set =  2'b10,
              reset= 2'b11;
    reg q_next=0;
    always @(posedge clk) begin
        case ({j,k}) 
            hold : q_next <= q;
            toggle: q_next <= ~q;
            set : q_next <= 1'b1;
            reset : q_next <= 1'b0;
         endcase
     end
     always @(posedge clk) begin
        q <= q_next;
        q_bar <= ~q_next; 
     end
endmodule
