`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 21.06.2026 18:23:13
// Design Name: 
// Module Name: shift_led_TB
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



module shift_led_TB();
    reg clk;
    reg b_right;
    reg b_left;
    wire [7:0] led;
    left_right_shift_led  dut(.b_right(b_right),.b_left(b_left),.clk(clk),.led(led));
    
    always #5 clk = ~clk;
    
    initial begin
        clk = 0;
        b_right = 0;
        b_left = 0;
        #50;
        b_right = 1; 
        #500;        
        b_right = 0; 
        #100;
        b_right = 1; 
        #500;        
        b_right = 0; 
        #100;
        b_left = 1;  
        #500;        
        b_left = 0;  
        #100;
        $finish;
    end
endmodule