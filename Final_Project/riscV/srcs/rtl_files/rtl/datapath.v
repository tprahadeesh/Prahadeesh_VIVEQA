module datapath(
  input wire        clk,
  input wire        reset,
  input wire        reg_WE,
  input wire        rs1_SEL,
  input wire        rs2_SEL,
  input wire        stall_F,
  input wire        stall_D,
  input wire        stall_E,
  input wire        stall_M,
  input wire        stall_WB,
  input wire        flush_F,
  input wire        flush_D,
  input wire        flush_E,
  input wire        flush_M,
  input wire        flush_WB,
  input wire [1:0]  pc_SEL,
  input wire [1:0]  reg_SEL,
  input wire [2:0]  imm_SEL,
  input wire [3:0]  ALU_SEL,
  input wire [31:0] Instr,
  input wire [31:0] memDataRD,
  output wire [31:0] pc,
  output wire [31:0] memDataWD,
  output wire [31:0] memAdrs,
  output wire [6:0]  opcode,
  output wire [6:0]  funct7,
  output wire [2:0]  funct3,
  output wire        jump,
  output wire [4:0]  rs1,
  output wire [4:0]  rs2,
  output wire [4:0]  rs3
);

  // ----------------------------- //
  // Fetch
  // ----------------------------- //
  
  wire [31:0]     pc_plus4_F, pc_F, instr_F;
  wire [31:0]     pc_now;
  reg [31:0]      pc_next = 0;

  wire            en_F;
  assign en_F = ~stall_F;


  mux2 #(.WIDTH(32)) MUX_pc_0 (
    .a(pc_plus4_F), 
    .b(pc_jump), 
    .sel(pc_SEL[0]), 
    .y(pc_now));


  // REG_fetch
  //  always @(posedge clk, posedge reset, posedge flush_F) begin
  always @(posedge clk) begin
    if (reset | flush_F) begin
      pc_next <= 0;
    end
    else if (en_F) begin
      pc_next <= pc_now;
    end
  end

  adder #(.WIDTH(32)) plus4 (
    .a(4), 
    .b(pc_next), 
    .y(pc_plus4_F));

  assign instr_F = Instr;                   // Instruction input from memory
  assign pc_F = pc_next;
  assign pc = pc_next;                      // PC for Instruction memory

  // ----------------------------- //
  // Decode
  // ----------------------------- //

  reg [31:0]      pc_plus4_D = 0, pc_D = 0, instr_D = 0;
  
  wire [4:0]      rs3_D;
  wire [31:0]     rdout1_D, rdout2_D, wrs3;
  wire [31:0]     ExtImm_D;

  wire            en_D;
  assign en_D = ~stall_D;

  // REG_decode
  // always @(posedge clk, posedge reset, posedge flush_D) begin
  always @(posedge clk) begin
    if (reset | flush_D) begin
      pc_plus4_D <= 0;
      pc_D <= 0;
      instr_D <= 0;
    end
    else if (en_D) begin
      pc_plus4_D <= pc_plus4_F;
      pc_D <= pc_F;
      instr_D <= instr_F;
    end
  end

  regfile regFILE (
      .rs1(instr_D[19:15]),
      .rs2(instr_D[24:20]),
      .wrs3(wrs3),
      .rs3(rs3_WB),
      .we(reg_WE),
      .clk(clk),
      .reset(reset),
      .rdout1(rdout1_D),
      .rdout2(rdout2_D));
  assign rs3_D = instr_D[11:7];

  extend extendImm(
      .Instr(instr_D[31:7]), 
      .ImmSrc(imm_SEL), 
      .ExtImm(ExtImm_D));
  


  assign opcode = instr_D[6:0];
  assign funct3 = instr_D[14:12];
  assign funct7 = instr_D[31:25];

  assign rs1 = instr_D[19:15];
  assign rs2 = instr_D[24:20];
  assign rs3 = instr_D[11:7];

  // ----------------------------- //
  // Execute
  // ----------------------------- //
  
  reg [31:0]      pc_plus4_E = 0, pc_E = 0, ExtImm_E = 0;
  reg [31:0]      rdout1_E = 0, rdout2_E = 0;
  reg [4:0]       rs3_E = 0;

  wire [31:0]     muxrs1, muxrs2;
  wire [31:0]     ALUResults_E;
  wire [31:0]     pcPlusImm_E;

  wire            en_E;
  assign en_E = ~stall_E;

  // REG_execute
  always @(posedge clk) begin
    if (reset | flush_E) begin
      pc_E <= 0;
      pc_plus4_E <= 0;
      ExtImm_E <= 0;
      rdout1_E <= 0;
      rdout2_E <= 0;
      rs3_E <= 0;
    end
    else if (en_E) begin
      pc_E <= pc_D;
      pc_plus4_E <= pc_plus4_D;
      ExtImm_E <= ExtImm_D;
      rdout1_E <= rdout1_D;
      rdout2_E <= rdout2_D;
      rs3_E <= rs3_D;
    end
  end

  mux2 #(.WIDTH(32)) MUX_rs1 (
      .a(rdout1_E), 
      .b(pc_E), 
      .sel(rs1_SEL), 
      .y(muxrs1));

  mux2 #(.WIDTH(32)) MUX_rs2 (
      .a(rdout2_E), 
      .b(ExtImm_E), 
      .sel(rs2_SEL), 
      .y(muxrs2));

  alu32 ALU (
      .a(muxrs1), 
      .b(muxrs2), 
      .ALUControl(ALU_SEL), 
      .result(ALUResults_E));

  adder #(.WIDTH(32)) ADDER_Imm (
      .a(pc_E), 
      .b(ExtImm_E), 
      .y(pcPlusImm_E));


    assign jump = ALUResults_E[0];




  // ----------------------------- //
  // Memory
  // ----------------------------- //

  reg [31:0]      pc_plus4_M = 0, pcPlusImm_M = 0, ExtImm_M = 0;
  reg [31:0]      rdout2_M = 0, ALUResults_M = 0;
  reg [4:0]       rs3_M = 0;

  wire [31:0]     pc_jump;
  wire [31:0]     memData_M;

  wire            en_M;
  assign en_M = ~stall_M;

  // REG_memory
  always @(posedge clk) begin
    if (reset | flush_M) begin
      pc_plus4_M <= 0;
      pcPlusImm_M <= 0;
      rdout2_M <= 0;
      ExtImm_M <= 0;
      ALUResults_M <= 0;
      rs3_M <= 0;
    end
    else if (en_M) begin
      ExtImm_M <= ExtImm_E;
      pc_plus4_M <= pc_plus4_E;
      pcPlusImm_M <= pcPlusImm_E;
      rdout2_M <= rdout2_E;
      ALUResults_M <= ALUResults_E;
      rs3_M <= rs3_E;
    end
  end

  assign memAdrs = ALUResults_M;

  mux2 #(.WIDTH(32)) MUX_pc_1 (
      .a(ALUResults_M),
      .b(pcPlusImm_M),
      .sel(pc_SEL[1]), 
      .y(pc_jump));

  assign memData_M = memDataRD;
  assign memDataWD = rdout2_M;

  // ----------------------------- //
  // Write Back
  // ----------------------------- //

  reg [31:0]      pc_plus4_WB = 0, memData_WB = 0, ALUResults_WB = 0;
  reg [31:0]      ExtImm_WB = 0;
  reg [4:0]       rs3_WB = 0;

  wire            en_WB;
  assign en_WB = ~stall_WB;

  // REG_writeback
  always @(posedge clk) begin
    if (reset | flush_WB) begin
      pc_plus4_WB <= 0;
      memData_WB <= 0;
      ALUResults_WB <= 0;
      ExtImm_WB <= 0;
      rs3_WB <= 0;
    end
    else if (en_WB) begin
      pc_plus4_WB <= pc_plus4_M;
      memData_WB <= memData_M;
      ALUResults_WB <= ALUResults_M;
      ExtImm_WB <= ExtImm_M;
      rs3_WB <= rs3_M;
    end
  end

  mux4 #(.WIDTH(32)) MUX_regfile (
      .a(memData_WB),
      .b(ALUResults_WB),
      .c(ExtImm_WB),
      .d(pc_plus4_WB),
      .sel(reg_SEL), 
      .y(wrs3));


endmodule