//
//	hazard_logic.v
//		
//


// reg_RD
//  00 -> none
//  01 -> rs1
//  10 -> rs2
//  11 -> rs1 & rs2

// reg_WE
//  0 -> none
//  1 -> rs3

module hazard_logic(
  input wire      clk,
  input wire      reset,
  input wire      reg_WE,
  input wire [1:0] reg_RD,
  input wire [4:0] rs1,
  input wire [4:0] rs2,
  input wire [4:0] rs3,
  input wire      jumping,
  output wire     flush_F,
  output wire     flush_D,
  output wire     flush_E,
  output wire     flush_M,
  output wire     flush_WB,
  output wire     stall_F,
  output wire     stall_D,
  output wire     stall_E,
  output wire     stall_M,
  output wire     stall_WB
);


  reg             flush_F_n = 0, flush_D_n = 0, flush_E_n = 0, flush_M_n = 0, flush_WB_n = 0;
  reg             stall_F_n = 0, stall_D_n = 0, stall_E_n = 0, stall_M_n = 0, stall_WB_n = 0;

  assign flush_F = flush_F_n;
  assign flush_D = flush_D_n;
  assign flush_E = flush_E_n;
  assign flush_M = flush_M_n;
  assign flush_WB = flush_WB_n;
  assign stall_F = stall_F_n;
  assign stall_D = stall_D_n;
  assign stall_E = stall_E_n;
  assign stall_M = stall_M_n;
  assign stall_WB = stall_WB_n;


  reg         rd_wr_collision = 0;
  //wire        rd_wr_collision;
  reg [31:0]  reg_reserve = 32'h00000000;

  // Hazard State Machine

  localparam OPERATIONAL_STATE = 2'b00;
  localparam COLLISION_STATE = 2'b01;
  localparam JUMP_STATE = 2'b10;
  reg [1:0]  current_state = OPERATIONAL_STATE;

  // State Transition

  always @(posedge clk) begin
    if (reset) begin
      current_state <= OPERATIONAL_STATE;
    end
    else begin
      case (current_state)
        OPERATIONAL_STATE:
          if (jumping) begin
            current_state <= JUMP_STATE;
          end
          else if (rd_wr_collision) begin
            current_state <= COLLISION_STATE;
          end
          else begin
            current_state <= OPERATIONAL_STATE;
          end
        JUMP_STATE:
          if (rd_wr_collision) begin
            current_state <= COLLISION_STATE;
          end
          else begin
            current_state <= OPERATIONAL_STATE;
          end
        COLLISION_STATE:
          if (jumping) begin
            current_state <= JUMP_STATE;
          end
          else if (rd_wr_collision) begin
            current_state <= COLLISION_STATE;
          end
          else begin
            current_state <= OPERATIONAL_STATE;
          end
        default:;
      endcase
    end
  end

  always @(*) begin
    if (jumping) begin
      flush_D_n = 1'b1;       // Kill wrong-path instruction in Decode
      flush_E_n = 1'b1;       // Clear Execute (branch data already captured by Memory)
      flush_M_n = 1'b0;       // DON'T flush Memory — branch/JAL must pass through
    end
    else if (current_state == JUMP_STATE) begin
      flush_D_n = 1'b1;       // Kill second wrong-path instruction entering Decode
      flush_E_n = 1'b1;       // Kill first wrong-path instruction in Execute
      flush_M_n = 1'b0;       // Branch itself is in Memory, let it survive
    end
    else if (rd_wr_collision) begin
      flush_D_n = 1'b0;
      flush_E_n = 1'b1;
      flush_M_n = 1'b0;
    end
    else begin
      flush_D_n = 1'b0;
      flush_E_n = 1'b0;
      flush_M_n = 1'b0;
    end
  end

  // Consolidated always block for updating reg_reserve to prevent multi-driven net errors
always @(posedge clk) begin
  if (reset) begin
    reg_reserve <= 32'h00000000;
  end
  else begin
    // Release reservation of write-back instruction
    if (reg_WE_WB)
      reg_reserve[rs3_WB] <= 1'b0;

    // Release reservation of flushed instruction
    if (flush_D_n & reg_WE & (rs3 != 0))
      reg_reserve[rs3] <= 1'b0;

    // Reserve register for incoming Decode instruction
    // BUT: Don't reserve if same register is being cleared by WriteBack!
    if (reg_WE & (rs3 != 0) & ~flush_D_n & !(reg_WE_WB & (rs3_WB == rs3)))
      reg_reserve[rs3] <= 1'b1;
  end
end
  // Clear on falling edge
  // always @(negedge clk) begin
  // end

  // Continuesly checking for a read write collision
  always @(*) begin
    case (reg_RD)
      2'b00:   rd_wr_collision = 1'b0;
      2'b01:   rd_wr_collision = reg_reserve[rs1];
      2'b10:   rd_wr_collision = reg_reserve[rs2];
      2'b11:   rd_wr_collision = reg_reserve[rs1] | reg_reserve[rs2];
    endcase
  end

  // assign rd_wr_collision = (reg_RD == 2'b00) ? 1'b0 : {(reg_RD == 2'b01) ? reg_reserve[rs1] : {(reg_RD == 2'b10) ? reg_reserve[rs2] : reg_reserve[rs1] | reg_reserve[rs2]}};

  always @(*) begin
    if (rd_wr_collision & ~jumping) begin
      stall_F_n = 1'b1;
      stall_D_n = 1'b1; 
      stall_E_n = 1'b0; 
     stall_M_n = 1'b0;   
    stall_WB_n = 1'b0;   
    end
    else begin
      stall_F_n = 1'b0;
      stall_D_n = 1'b0; 
      stall_E_n = 1'b0; 
      stall_M_n = 1'b0;   
      stall_WB_n = 1'b0;
    end
  end


  // ----------------------------- //
  // Execute
  // ----------------------------- //

  reg [4:0]       rs3_E = 0;
  reg             reg_WE_E = 0;
  wire            enable_E;

  assign enable_E       = ~stall_E_n;

  // REG_execute
  always @(posedge clk) begin
    if (reset | flush_E_n) begin
      rs3_E <= 0;
      reg_WE_E <= 0;
    end
    else if (enable_E) begin
      rs3_E <= rs3;
      reg_WE_E <= reg_WE;
    end
  end

  // ----------------------------- //
  // Memory
  // ----------------------------- //

  reg [4:0]       rs3_M = 0;
  reg             reg_WE_M = 0;
  wire            enable_M;

  assign enable_M       = ~stall_M_n;

  // REG_memory
  always @(posedge clk) begin
    if (reset | flush_M_n) begin
      rs3_M <= 0;
      reg_WE_M <= 0;
    end
    else if (enable_M) begin
      rs3_M <= rs3_E;
      reg_WE_M <= reg_WE_E;
    end
  end

  // // ----------------------------- //
  // // Write Back
  // // ----------------------------- //

  reg [4:0]       rs3_WB = 0;
  reg             reg_WE_WB = 0;
  wire            enable_WB;

  assign enable_WB       = ~stall_WB_n;

  // REG_writeback
  always @(posedge clk) begin
    if (reset | flush_WB_n) begin
      reg_WE_WB <= 0;
      rs3_WB <= 0;
    end
    else if (enable_WB) begin
      reg_WE_WB <= reg_WE_M;
      rs3_WB <= rs3_M;
    end
  end

endmodule