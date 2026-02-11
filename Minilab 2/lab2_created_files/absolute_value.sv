module absolute_value #(
    parameter PIXEL_SIZE = 12
) (
    input clk,
    input rst_n,
    input [PIXEL_SIZE-1:0] pixel,
    output [PIXEL_SIZE-1:0] outPixel
);

    always_ff @(posedge clk or negedge rst_n)
        if (~rst_n) outPixel <= {PIXEL_SIZE{1'b0}};
        else outPixel <= {1'b0, pixel};
endmodule