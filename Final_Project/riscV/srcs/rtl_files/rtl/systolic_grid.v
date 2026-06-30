`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: systolic_grid
// Description: NxN systolic array grid of Processing Elements (PEs).
//              Input A rows are fed from the left, input B columns from the top.
//              Data flows rightward (A) and downward (B) through the mesh.
//
//              For a 4x4 array:
//                       b_col[0]  b_col[1]  b_col[2]  b_col[3]
//                          |         |         |         |
//              a_row[0]->[ PE00 ]->[ PE01 ]->[ PE02 ]->[ PE03 ]
//                          |         |         |         |
//              a_row[1]->[ PE10 ]->[ PE11 ]->[ PE12 ]->[ PE13 ]
//                          |         |         |         |
//              a_row[2]->[ PE20 ]->[ PE21 ]->[ PE22 ]->[ PE23 ]
//                          |         |         |         |
//              a_row[3]->[ PE30 ]->[ PE31 ]->[ PE32 ]->[ PE33 ]
//
//              After 2N-1 cycles, acc[i][j] = sum_k(A[i][k] * B[k][j])
//////////////////////////////////////////////////////////////////////////////////

module systolic_grid #(
    parameter N          = 4,                       // Array dimension (NxN)
    parameter DATA_WIDTH = 8,                       // Width of input data
    parameter ACC_WIDTH  = 2 * DATA_WIDTH + 4       // Accumulator width
)(
    input  wire                          clk,
    input  wire                          reset,
    input  wire                          enable,
    input  wire                          clear_acc,
    input  wire [N*DATA_WIDTH-1:0]       a_row,     // N inputs fed from the left  (one per row)
    input  wire [N*DATA_WIDTH-1:0]       b_col,     // N inputs fed from the top   (one per column)
    output wire [N*N*ACC_WIDTH-1:0]      result     // N*N accumulated results (flattened)
);

    // Internal wires connecting PEs
    // Horizontal A connections: a_wire[row][col] connects PE[row][col].a_out -> PE[row][col+1].a_in
    // Vertical B connections:   b_wire[row][col] connects PE[row][col].b_out -> PE[row+1][col].b_in
    wire [DATA_WIDTH-1:0] a_wire [0:N-1][0:N];      // N rows, N+1 columns (includes input & output)
    wire [DATA_WIDTH-1:0] b_wire [0:N][0:N-1];      // N+1 rows, N columns (includes input & output)
    wire [ACC_WIDTH-1:0]  acc_wire [0:N-1][0:N-1];   // N*N accumulators

    // Connect external inputs to the left edge (A) and top edge (B)
    genvar i, j;
    generate
        for (i = 0; i < N; i = i + 1) begin : gen_inputs
            assign a_wire[i][0] = a_row[i*DATA_WIDTH +: DATA_WIDTH];    // Row i input from left
            assign b_wire[0][i] = b_col[i*DATA_WIDTH +: DATA_WIDTH];    // Col i input from top
        end
    endgenerate

    // Instantiate NxN grid of PEs
    generate
        for (i = 0; i < N; i = i + 1) begin : gen_row
            for (j = 0; j < N; j = j + 1) begin : gen_col
                pe #(
                    .DATA_WIDTH(DATA_WIDTH),
                    .ACC_WIDTH(ACC_WIDTH)
                ) pe_inst (
                    .clk(clk),
                    .reset(reset),
                    .enable(enable),
                    .clear_acc(clear_acc),
                    .a_in(a_wire[i][j]),
                    .b_in(b_wire[i][j]),
                    .a_out(a_wire[i][j+1]),
                    .b_out(b_wire[i+1][j]),
                    .acc(acc_wire[i][j])
                );

                // Flatten results: result[(i*N+j)*ACC_WIDTH +: ACC_WIDTH] = acc[i][j]
                assign result[(i*N+j)*ACC_WIDTH +: ACC_WIDTH] = acc_wire[i][j];
            end
        end
    endgenerate

endmodule
