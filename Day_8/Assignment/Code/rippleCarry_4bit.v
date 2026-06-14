`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11.06.2026 22:58:45
// Design Name: 
// Module Name: rippleCarry_4bit
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


module rippleCarry_4bit(
    input [3:0]a,b,
    input cin,
    output [3:0]sum,
    output cout
);
    wire [2:0]carry_prop;
    adder1bit a1(a[0],b[0],cin,sum[0],carry_prop[0]);
    adder1bit a2(a[1],b[1],carry_prop[0],sum[1],carry_prop[1]);
    adder1bit a3(a[2],b[2],carry_prop[1],sum[2],carry_prop[2]);
    adder1bit a4(a[3],b[3],carry_prop[2],sum[3],cout);
endmodule

module adder1bit(
    input a,b,cin,
    output sum,cout
    );
    assign sum = a^b^cin;
    assign cout = (a&b) |(b&cin) |(a&cin);
endmodule