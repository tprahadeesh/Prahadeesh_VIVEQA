`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 15.06.2026 12:40:23
// Design Name: 
// Module Name: Led_blink
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

module Led_blink(clk,led,clk_out);
input clk;
output reg led=0;
output clk_out;

reg [23:0]counter=0;
assign clk_out=clk;
always @(posedge clk)begin  
   if(counter==24'd11_999_999)begin
      counter = 24'd0;
	  led=~led;
   end else
      counter=counter +1;
end
endmodule
