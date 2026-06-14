`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.06.2026 23:03:14
// Design Name: 
// Module Name: fsm_110_detector
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


module fsm_110_detector(input x,clk,rst, output reg y);
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
        y = 1'b0;
        case(current_state)
            s1: begin
                if (x) next_state = s2;
                else next_state = s1;
            end
            s2: begin
                if (x) next_state = s3;
                else next_state = s1;
            end
            s3: begin 
                if (x) next_state = s3;
                else next_state = s4;
            end
            s4: begin 
                y = 1'b1;
                if (x) next_state = s2;
                else next_state = s1;
            end
        endcase 
    end
        
              
           
endmodule
