`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.06.2026 23:47:47
// Design Name: 
// Module Name: Largest_number
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


module Largest_number(input [1:0]x, input clk,rst, output reg [1:0]y);
    parameter s1 = 2'b00,
              s2 = 2'b01,
              s3 = 2'b10,
              s4 = 2'b11;
    reg [1:0]current_state, next_state;
    always @(posedge clk) begin
        if(rst) begin
            current_state <= s1;
        end
        else begin
            current_state <= next_state;
        end
    end
    always @(*) begin
        case(current_state)
            s1: begin
                y = 2'b00;
                if (x==2'b01) begin 
                    next_state = s2;
                end
                else if (x==2'b10) begin 
                    next_state = s3;
                end
                else if (x==2'b11) begin 
                    next_state = s4;
                end
                else next_state = s1;
            end
            s2: begin
                y = 2'b01;
                if (x==2'b10) begin 
                    next_state = s3;
                end
                else if (x==2'b11) begin 
                    next_state = s4;
                end
                else next_state = s2;
            end
            s3: begin
                y = 2'b10;
                if (x==2'b11) begin 
                    next_state = s4;
                end
                else next_state = s3;
            end
            s4: begin y = 2'b11; next_state = s4; end
       endcase
       end        
endmodule
