module flopr #(
	parameter WIDTH = 32,
	parameter INIT = 0
)(
	input wire [WIDTH - 1:0]	d,
	output reg [WIDTH - 1:0]	q,
	input wire					clk,
	input wire					reset
);
	
	initial q = INIT;
	always @(posedge clk, posedge reset) begin
		q <= reset ? {WIDTH{1'b0}} : d;
	end

endmodule