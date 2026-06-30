`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: systolic_array_top
// Description: Top-level wrapper for the systolic array accelerator.
//              Includes:
//                - Input buffers for Matrix A (NxN) and Matrix B (NxN)
//                - Output buffer for Result Matrix C (NxN)
//                - Control FSM (IDLE -> LOAD -> COMPUTE -> DONE)
//                - MMIO interface for CPU communication
//
//              Memory Map (offsets from base address):
//                0x000 - 0x03F : Matrix A buffer  (16 words for 4x4)
//                0x040 - 0x07F : Matrix B buffer  (16 words for 4x4)
//                0x080 - 0x0BF : Matrix C results (16 words for 4x4, read-only)
//                0x0C0         : Control register  (write bit[0]=1 to start)
//                0x0C4         : Status register   (bit[0]=1 when done)
//////////////////////////////////////////////////////////////////////////////////

module systolic_array_top #(
    parameter N          = 4,                       // Matrix dimension (NxN)
    parameter DATA_WIDTH = 8,                       // Input element width
    parameter ACC_WIDTH  = 2 * DATA_WIDTH + 4       // Accumulator width
)(
    input  wire                clk,
    input  wire                reset,

    // MMIO Interface (directly from the CPU memory bus)
    input  wire [31:0]         addr,                // Address (offset from SA base)
    input  wire [31:0]         wdata,               // Write data from CPU
    input  wire                we,                  // Write enable
    output reg  [31:0]         rdata                // Read data to CPU
);

    // ─────────────────────────────────────────────
    // FSM States
    // ─────────────────────────────────────────────
    localparam STATE_IDLE    = 3'd0;
    localparam STATE_CLEAR   = 3'd1;    // Clear accumulators before compute
    localparam STATE_COMPUTE = 3'd2;    // Feed data through the systolic array
    localparam STATE_DONE    = 3'd3;    // Results ready

    reg [2:0]  state = STATE_IDLE;

    // ─────────────────────────────────────────────
    // Address decode constants (byte offsets)
    // ─────────────────────────────────────────────
    localparam ADDR_A_BASE   = 12'h000;    // Matrix A: 0x000 to 0x03F (N*N words)
    localparam ADDR_B_BASE   = 12'h040;    // Matrix B: 0x040 to 0x07F
    localparam ADDR_C_BASE   = 12'h080;    // Matrix C: 0x080 to 0x0BF
    localparam ADDR_CTRL     = 12'h0C0;    // Control register
    localparam ADDR_STATUS   = 12'h0C4;    // Status register

    // ─────────────────────────────────────────────
    // Input Buffers: A[N][N] and B[N][N]
    // Stored as N*N array of DATA_WIDTH-bit values
    // ─────────────────────────────────────────────
    reg [DATA_WIDTH-1:0] buf_a [0:N*N-1];
    reg [DATA_WIDTH-1:0] buf_b [0:N*N-1];

    // ─────────────────────────────────────────────
    // Output Buffer: C[N][N]
    // Stored as N*N array of 32-bit values (sign-extended from ACC_WIDTH)
    // ─────────────────────────────────────────────
    reg [31:0] buf_c [0:N*N-1];

    // ─────────────────────────────────────────────
    // Control / Status registers
    // ─────────────────────────────────────────────
    reg        ctrl_start = 0;
    reg        status_done = 0;

    // ─────────────────────────────────────────────
    // Cycle counter for systolic computation
    // Total feeding cycles = 2*N - 1
    // ─────────────────────────────────────────────
    localparam TOTAL_CYCLES = 2 * N - 1;
    reg [7:0]  cycle_count = 0;

    // ─────────────────────────────────────────────
    // Systolic Grid signals
    // ─────────────────────────────────────────────
    reg                           grid_enable;
    reg                           grid_clear;
    reg  [N*DATA_WIDTH-1:0]       grid_a_row;    // Staggered row inputs for A
    reg  [N*DATA_WIDTH-1:0]       grid_b_col;    // Staggered column inputs for B
    wire [N*N*ACC_WIDTH-1:0]      grid_result;   // Flat result from grid

    // ─────────────────────────────────────────────
    // Systolic Grid instantiation
    // ─────────────────────────────────────────────
    systolic_grid #(
        .N(N),
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH)
    ) grid (
        .clk(clk),
        .reset(reset),
        .enable(grid_enable),
        .clear_acc(grid_clear),
        .a_row(grid_a_row),
        .b_col(grid_b_col),
        .result(grid_result)
    );

    // ─────────────────────────────────────────────
    // Initialize buffers
    // ─────────────────────────────────────────────
    integer init_i;
    initial begin
        for (init_i = 0; init_i < N*N; init_i = init_i + 1) begin
            buf_a[init_i] = 0;
            buf_b[init_i] = 0;
            buf_c[init_i] = 0;
        end
    end

    // ─────────────────────────────────────────────
    // MMIO Write logic
    //   CPU writes to A buffer, B buffer, or control reg
    // ─────────────────────────────────────────────
    wire [11:0] local_addr;
    assign local_addr = addr[11:0];    // Use lower 12 bits as offset

    always @(posedge clk) begin
        if (reset) begin
            ctrl_start <= 0;
        end
        else if (we && state == STATE_IDLE) begin
            if (local_addr >= ADDR_A_BASE && local_addr < ADDR_B_BASE) begin
                // Write to Matrix A buffer
                // Word index = (addr - A_BASE) / 4
                buf_a[(local_addr - ADDR_A_BASE) >> 2] <= wdata[DATA_WIDTH-1:0];
            end
            else if (local_addr >= ADDR_B_BASE && local_addr < ADDR_C_BASE) begin
                // Write to Matrix B buffer
                buf_b[(local_addr - ADDR_B_BASE) >> 2] <= wdata[DATA_WIDTH-1:0];
            end
            else if (local_addr == ADDR_CTRL) begin
                ctrl_start <= wdata[0];
            end
        end
        else begin
            // Auto-clear start bit once FSM leaves IDLE
            if (state != STATE_IDLE)
                ctrl_start <= 0;
        end
    end

    // ─────────────────────────────────────────────
    // MMIO Read logic
    //   CPU reads from C buffer or status register
    // ─────────────────────────────────────────────
    always @(*) begin
        rdata = 32'h00000000;
        if (local_addr >= ADDR_A_BASE && local_addr < ADDR_B_BASE) begin
            rdata = {{(32-DATA_WIDTH){1'b0}}, buf_a[(local_addr - ADDR_A_BASE) >> 2]};
        end
        else if (local_addr >= ADDR_B_BASE && local_addr < ADDR_C_BASE) begin
            rdata = {{(32-DATA_WIDTH){1'b0}}, buf_b[(local_addr - ADDR_B_BASE) >> 2]};
        end
        else if (local_addr >= ADDR_C_BASE && local_addr < ADDR_CTRL) begin
            rdata = buf_c[(local_addr - ADDR_C_BASE) >> 2];
        end
        else if (local_addr == ADDR_STATUS) begin
            rdata = {31'b0, status_done};
        end
        else begin
            rdata = 32'h00000000;
        end
    end

    // ─────────────────────────────────────────────
    // Staggered data feeding logic
    //   For cycle k (0-indexed):
    //     Row i feeds A[i][k-i] if 0 <= k-i < N, else 0
    //     Col j feeds B[k-j][j] if 0 <= k-j < N, else 0
    // ─────────────────────────────────────────────
    integer feed_i;
    always @(*) begin
        grid_a_row = 0;
        grid_b_col = 0;
        for (feed_i = 0; feed_i < N; feed_i = feed_i + 1) begin
            // Feed row i of A: element A[i][cycle_count - i]
            if (cycle_count >= feed_i && (cycle_count - feed_i) < N) begin
                grid_a_row[feed_i*DATA_WIDTH +: DATA_WIDTH] = buf_a[feed_i * N + (cycle_count - feed_i)];
            end
            // Feed col i of B: element B[cycle_count - i][i]
            if (cycle_count >= feed_i && (cycle_count - feed_i) < N) begin
                grid_b_col[feed_i*DATA_WIDTH +: DATA_WIDTH] = buf_b[(cycle_count - feed_i) * N + feed_i];
            end
        end
    end

    // ─────────────────────────────────────────────
    // Control FSM
    // ─────────────────────────────────────────────
    integer res_i;
    always @(posedge clk) begin
        if (reset) begin
            state       <= STATE_IDLE;
            grid_enable <= 0;
            grid_clear  <= 0;
            cycle_count <= 0;
            status_done <= 0;
        end
        else begin
            case (state)
                STATE_IDLE: begin
                    grid_enable <= 0;
                    grid_clear  <= 0;
                    if (ctrl_start) begin
                        state       <= STATE_CLEAR;
                        grid_clear  <= 1;           // Pulse clear for 1 cycle
                        status_done <= 0;
                    end
                end

                STATE_CLEAR: begin
                    grid_clear  <= 0;               // Clear done after 1 cycle
                    grid_enable <= 1;
                    cycle_count <= 0;
                    state       <= STATE_COMPUTE;
                end

                STATE_COMPUTE: begin
                    grid_enable <= 1;
                    cycle_count <= cycle_count + 1;
                    if (cycle_count == TOTAL_CYCLES - 1) begin
                        state       <= STATE_DONE;
                        grid_enable <= 0;
                    end
                end

                STATE_DONE: begin
                    // Latch results from the grid into the output buffer
                    for (res_i = 0; res_i < N*N; res_i = res_i + 1) begin
                        // Sign-extend accumulator to 32 bits
                        buf_c[res_i] <= {{(32-ACC_WIDTH){grid_result[res_i*ACC_WIDTH + ACC_WIDTH - 1]}},
                                          grid_result[res_i*ACC_WIDTH +: ACC_WIDTH]};
                    end
                    status_done <= 1;
                    state       <= STATE_IDLE;
                end

                default: state <= STATE_IDLE;
            endcase
        end
    end

endmodule
