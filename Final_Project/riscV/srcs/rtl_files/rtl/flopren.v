module flopren #(
	parameter WIDTH = 32,
	parameter INIT = 0
)(
	input wire [WIDTH - 1:0]	d,
	output wire [WIDTH - 1:0]	q,
	input wire					clk,
	input wire					enable,
	input wire					reset
);
	
	reg [WIDTH - 1:0]         q_n;
	
	initial q_n = INIT;
	always @(posedge clk, posedge reset) begin
		q_n <= reset ? {WIDTH{1'b0}} : (enable ? d : q_n);
  end

  assign q = q_n;

endmodule