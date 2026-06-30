module dmem(
	input wire [31:0]	a,
	output reg [31:0]	rd = 0,
	input wire [31:0]	wd,
	input wire 			clk,
	input wire 			we,
	input wire [2:0]	mode,
	input wire 			reset
);
	
	reg [7:0] mem [0:255];
	
	integer i;
	initial begin
		for (i = 0; i < 256; i = i + 1) begin
			mem[i] = 8'h00;
		end		
	end
		
	always @(posedge clk) begin
		if (we) begin
			case (mode)
				3'b000:	{mem[a], mem[a + 1], mem[a + 2], mem[a + 3]} <= wd;	// 4 byte mode (32 bit)
				3'b001:	{mem[a], mem[a + 1]} <= wd[15:0];					// 2 byte mode (16 bit)
				3'b101:	{mem[a], mem[a + 1]} <= wd[15:0];					// 2 byte mode (16 bit)
				3'b010: mem[a] <= wd[7:0];									// 1 byte mode (8 bit)
				3'b110: mem[a] <= wd[7:0];									// 1 byte mode (8 bit)
				default:{mem[a], mem[a + 1], mem[a + 2], mem[a + 3]} <= wd;	// 4 byte mode (32 bit)
			endcase
		end
	end
	
	always @(*) begin
		case (mode)
			3'b000: rd = {mem[a], mem[a + 1], mem[a + 2], mem[a + 3]};	// 4 byte mode (32 bit)
			3'b001: rd = {{16{1'b0}}, mem[a], mem[a + 1]};				// 2 byte not signextended
			3'b101:	rd = {{16{mem[a][7]}}, mem[a], mem[a + 1]};		// 2 byte signextended
			3'b010: rd = {{24{1'b0}}, mem[a]};							// 1 byte not signextended
			3'b110: rd = {{24{mem[a][7]}}, mem[a]};					// 1 byte signextended
			default:rd = {mem[a], mem[a + 1], mem[a + 2], mem[a + 3]};	// 4 byte mode (32 bit)
		endcase
	end
	
endmodule