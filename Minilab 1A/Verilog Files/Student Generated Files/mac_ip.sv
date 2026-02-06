module MAC_IP(
    input clk,
	input rst_n,
	input En,
	input Clr,
	input [7:0] Ain,
	input [7:0] Bin,
	output reg [23:0] Cout
);

wire [23:0] mult;

LPM_MULT_IP theMult (.dataa(Ain), .datab(Bin), .result(mult));
LPM_ADD_SUB_IP theAdder (.aclr(~rst_n), .clken(En), .clock(clk), .dataa((Clr) ? 24'h0 : mult), 
                .datab((Clr) ? 24'h0 : Cout), .result(Cout));

endmodule