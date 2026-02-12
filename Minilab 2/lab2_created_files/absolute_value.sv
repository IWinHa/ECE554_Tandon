module absolute_value #(
    parameter PIXEL_SIZE = 12
) (
    input clk,
    input rst_n,
    input signed [PIXEL_SIZE+2:0] pixel,
    output reg signed [PIXEL_SIZE-1:0] outPixel
);

    always_ff @(posedge clk or negedge rst_n)
        if (~rst_n) outPixel <= {PIXEL_SIZE{1'b0}};
        else begin
            if (pixel < 0) outPixel <= -pixel[PIXEL_SIZE-1:0];
            else outPixel <= pixel[PIXEL_SIZE-1:0];
        end
endmodule