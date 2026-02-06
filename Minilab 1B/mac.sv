module MAC #(parameter DATA_WIDTH = 8) (
	input clk,
	input rst_n,
	input En,
	input Clr,
	input [DATA_WIDTH-1:0] Ain,
	input [DATA_WIDTH-1:0] Bin,
	output reg [DATA_WIDTH*3-1:0] Cout
);

	wire [DATA_WIDTH*3-1:0] multOut;
	reg [DATA_WIDTH*3-1:0] tempFlop;

LPM_MULT_IP theMult (
	.dataa(Ain),
	.datab(Bin),
	.result(multOut)
);

always_ff @(posedge clk) begin
	tempFlop <= multOut;
end
	
always_ff @(posedge clk or negedge rst_n)
	if (~rst_n) Cout <= {(DATA_WIDTH*3-1){1'b0}};
	else if (Clr) Cout <= {(DATA_WIDTH*3-1){1'b0}};
	else if (En) Cout <= tempFlop + Cout;

endmodule
