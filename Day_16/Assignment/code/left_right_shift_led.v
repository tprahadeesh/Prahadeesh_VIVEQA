`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.06.2026 10:13:36
// Design Name: 
// Module Name: left_right_shift_led
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


module left_right_shift_led(input b_right,b_left,clk, output reg [7:0]led = 8'b10000000);
    wire pulse_right,pulse_left;
    debounce d1(clk,b_right,pulse_right);
    debounce d2(clk,b_left,pulse_left);
    always @(posedge clk) begin
        if(pulse_right) begin
            led <= {led[0],led[7:1]};
        end
        else if (pulse_left) begin
            led <= {led[6:0],led[7]};
        end
        else begin
            led <= led;
        end
     end
    
endmodule

module debounce(input clk,button, output pulse);
    reg q1,q2;
    always @(posedge clk) begin
        q1 <= button;
        q2 <= q1;
    end
    assign pulse = q1 & ~q2;
endmodule