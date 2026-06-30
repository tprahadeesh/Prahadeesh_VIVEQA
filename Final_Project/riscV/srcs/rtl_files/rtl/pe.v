`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: pe
// Description: Single Processing Element (PE) for the systolic array.
//              Performs multiply-accumulate (MAC) operation.
//              Passes input 'a' to the right and input 'b' downward.
//
//              Data flow:
//                      b_in
//                       |
//              a_in -> [PE] -> a_out
//                       |
//                      b_out
//
//              Operation: acc <= acc + (a_in * b_in)
//////////////////////////////////////////////////////////////////////////////////

module pe #(
    parameter DATA_WIDTH = 8,                      // Width of input operands
    parameter ACC_WIDTH  = 2 * DATA_WIDTH + 4      // Extra bits to prevent overflow during accumulation
)(
    input  wire                    clk,
    input  wire                    reset,
    input  wire                    enable,          // Compute enable
    input  wire                    clear_acc,       // Clear accumulator (before new computation)
    input  wire [DATA_WIDTH-1:0]   a_in,            // Input from left neighbor (Matrix A element)
    input  wire [DATA_WIDTH-1:0]   b_in,            // Input from top neighbor (Matrix B element)
    output reg  [DATA_WIDTH-1:0]   a_out,           // Output to right neighbor
    output reg  [DATA_WIDTH-1:0]   b_out,           // Output to bottom neighbor
    output reg  [ACC_WIDTH-1:0]    acc              // Accumulated result (one element of C)
);

    wire signed [DATA_WIDTH-1:0]   a_signed;
    wire signed [DATA_WIDTH-1:0]   b_signed;
    wire signed [ACC_WIDTH-1:0]    product;

    assign a_signed = a_in;
    assign b_signed = b_in;
    assign product  = a_signed * b_signed;

    always @(posedge clk) begin
        if (reset || clear_acc) begin
            a_out <= 0;
            b_out <= 0;
            acc   <= 0;
        end
        else if (enable) begin
            a_out <= a_in;                    // Pass A to the right
            b_out <= b_in;                    // Pass B downward
            acc   <= acc + product;           // Multiply-Accumulate
        end
    end

endmodule
