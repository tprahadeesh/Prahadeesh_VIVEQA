`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 26.06.2026 00:14:34
// Design Name: 
// Module Name: extend
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


module extend(
	input wire [24:0]	Instr,
	input wire [2:0]	ImmSrc,
	output reg [31:0]	ExtImm
);
	
	
	always @(ImmSrc, Instr) begin
		case (ImmSrc)
			3'b000:	ExtImm = {Instr[24:5], {12{1'b0}}};									    // U-Type
			3'b001:	ExtImm = {{21{Instr[24]}}, Instr[23:18], Instr[4:0]};					// S-Type
			3'b010:	ExtImm = {{20{Instr[24]}}, Instr[0], Instr[23:18], Instr[4:1], 1'b0};	// B-Type
			3'b011:	ExtImm = {{21{Instr[24]}}, Instr[23:13]};								// I-Type
			3'b100:	ExtImm = {{12{Instr[24]}}, Instr[12:5], Instr[13], Instr[23:14], 1'b0}; // J-Type
			default:ExtImm = {32{1'b0}};
		endcase
	end

endmodule
