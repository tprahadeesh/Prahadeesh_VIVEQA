
module imem(
	input wire [31:0]	a,
	output wire [31:0]	rd
);
	
	reg [31:0] mem [0:255];

	parameter INITIAL_DATA_PATH = "C:/Users/Prahadeesh TN/riscV/source/imem.dat";
	
	initial
		$readmemh(INITIAL_DATA_PATH, mem);
	
	/* verilator lint_off WIDTH */
	assign rd = mem[a[31:2]];
	/* verilator lint_off WIDTH */

endmodule