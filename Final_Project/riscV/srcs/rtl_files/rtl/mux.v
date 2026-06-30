module mux2 #(
	parameter WIDTH = 32
)(
	input wire [WIDTH - 1:0]	a,
	input wire [WIDTH - 1:0]	b,
	input wire 					sel,
	output wire [WIDTH - 1:0]	y
);

	assign y = sel ? b : a;

endmodule

module mux4 #(
	parameter WIDTH = 32
)(
	input wire [WIDTH - 1:0]	a,
	input wire [WIDTH - 1:0]	b,
	input wire [WIDTH - 1:0]	c,
	input wire [WIDTH - 1:0]	d,
    input wire [1:0]			sel,
	output reg [WIDTH - 1:0]	y
);

    always @(*) begin
        case (sel)
            2'b00:  y = a;
            2'b01:  y = b;
            2'b10:  y = c;
            2'b11:  y = d;
        endcase
    end

endmodule