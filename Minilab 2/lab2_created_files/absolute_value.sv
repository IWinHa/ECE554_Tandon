module absolute_value #(
    parameter PIXEL_SIZE = 12
) (
    input clk,
    input rst_n,
    input signed [PIXEL_SIZE+3:0] pixel,
    input valid_in,
    output reg [PIXEL_SIZE-1:0] outPixel,
    output reg valid_out
);

    integer MAX_VAL = (1 << PIXEL_SIZE) - 1;
    wire [PIXEL_SIZE+3:0] temp_pixel = (pixel < 0) ? -pixel : pixel;

    always_ff @(posedge clk or negedge rst_n)
        if (~rst_n) outPixel <= {PIXEL_SIZE{1'b0}};
        else begin
            if (temp_pixel > MAX_VAL) outPixel <= MAX_VAL;
            else outPixel <= temp_pixel[PIXEL_SIZE-1:0];
        end

    always_ff @(posedge clk) valid_out <= valid_in;
endmodule