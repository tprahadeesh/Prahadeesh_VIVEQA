`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: fpga_top
// Description: Board-level top module that instantiates the RISC-V CPU core,
//              instruction memory, data memory, and systolic array accelerator.
//              Includes a clock divider and interfaces to physical LEDs/buttons.
//
//              Memory Map:
//                0x0000 - 0x0FFF : Data Memory (dmem)
//                0x1000 - 0x1FFF : Systolic Array Accelerator (MMIO)
//                  0x1000-0x103F : Matrix A input buffer
//                  0x1040-0x107F : Matrix B input buffer
//                  0x1080-0x10BF : Matrix C result buffer (read-only)
//                  0x10C0        : Control register (bit 0 = start)
//                  0x10C4        : Status register  (bit 0 = done)
//////////////////////////////////////////////////////////////////////////////////

module fpga_top (
    input wire clk,          // Board system clock
    input wire reset_n,      // Board active-low reset button (inverts internally)
    output wire [7:0] leds   // 8 Board LEDs to display program status
);

  // Invert active-low reset to active-high for the core
  wire rst;
  assign rst = ~reset_n;

  // Clock Divider to slow down execution to ~1.43 Hz (on 24MHz clock) so LEDs are visible
  reg [23:0] clk_div = 0;
  always @(posedge clk) begin
    clk_div <= clk_div + 1;
  end

  // CPU clock driven by the slow divided clock (24MHz / 2^24)
  wire cpu_clk;
  assign cpu_clk = clk_div[1]; 

  // Internal interconnects
  wire [31:0] pc;
  wire [31:0] instr;
  (* mark_debug = "true" *) wire [31:0] mem_addr;
  (* mark_debug = "true" *) wire [31:0] mem_wd;
  wire [31:0] mem_rd;
  wire        dmem_we;
  wire [2:0]  dmem_sel;

  // ─────────────────────────────────────────────
  // Address Decoder
  //   addr < 0x1000  → Data Memory
  //   addr >= 0x1000 → Systolic Array Accelerator
  // ─────────────────────────────────────────────
  wire sel_dmem;
  wire sel_sa;
  assign sel_dmem = (mem_addr < 32'h00001000);
  assign sel_sa   = ~sel_dmem;

  // Separate read-data buses
  wire [31:0] dmem_rd;
  wire [31:0] sa_rd;

  // Mux read data back to CPU based on address region
  assign mem_rd = sel_dmem ? dmem_rd : sa_rd;

  // Route write enables to the correct peripheral
  (* mark_debug = "true" *) wire dmem_we_actual;
  wire sa_we;
  assign dmem_we_actual = dmem_we & sel_dmem;
  assign sa_we          = dmem_we & sel_sa;

  // CPU core instantiation
  top cpu_core (
    .clk(cpu_clk),
    .reset(rst),
    .Instr(instr),
    .memDataRD(mem_rd),
    .dmem_WE(dmem_we),
    .dmem_SEL(dmem_sel),
    .pc(pc),
    .memAdrs(mem_addr),
    .memDataWD(mem_wd)
  );

  // Instruction Memory instantiation
  imem instr_mem (
    .a(pc),
    .rd(instr)
  );

  // Data Memory instantiation
  dmem data_mem (
    .a(mem_addr),
    .rd(dmem_rd),
    .wd(mem_wd),
    .clk(cpu_clk),
    .we(dmem_we_actual),
    .mode(dmem_sel),
    .reset(rst)
  );

  // ─────────────────────────────────────────────
  // Systolic Array Accelerator (MMIO)
  //   Address offset = mem_addr - 0x1000
  //   4x4 array, 8-bit elements, 20-bit accumulator
  // ─────────────────────────────────────────────
  systolic_array_top #(
    .N(4),
    .DATA_WIDTH(8),
    .ACC_WIDTH(20)
  ) sa_accel (
    .clk(cpu_clk),
    .reset(rst),
    .addr(mem_addr - 32'h00001000),   // Convert to local offset
    .wdata(mem_wd),
    .we(sa_we),
    .rdata(sa_rd)
  );

  // Display lower bits of PC (word-aligned) on LEDs to visualize instruction stepping
  assign leds = pc[9:2];

endmodule
