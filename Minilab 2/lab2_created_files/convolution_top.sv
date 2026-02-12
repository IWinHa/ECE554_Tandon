module convolution_top #(
    parameter ROW_SIZE = 1280,
    parameter PIXEL_SIZE = 12
) (
    input clk,
    input rst_n,
    input [PIXEL_SIZE-1:0] input_pixel,
    input signed [PIXEL_SIZE-1:0] input_filter [-1:1] [-1:1],
    output [PIXEL_SIZE-1:0] output_pixel
    // TODO: Add stuff here
);

    wire [PIXEL_SIZE-1:0] first_buffer_pixel;
    wire [PIXEL_SIZE-1:0] gray_pixel;
    wire [PIXEL_SIZE+2:0] convoluted_pixel;
    
    row_buffer #(.ROW_SIZE(ROW_SIZE), .PIXEL_SIZE(PIXEL_SIZE)) initial_buffer (
        .clk(clk),
        .rst_n(rst_n),
        .pixel(input_pixel),
        .buffered_pixel(first_buffer_pixel)
    );

    bayer_generator #(.PIXEL_SIZE(PIXEL_SIZE)) convert_to_grayscale (
        .clk(clk),
        .rst_n(rst_n),
        .pixel_from_queue(first_buffer_pixel),
        .pixel_raw(input_pixel),
        .pixel_out(gray_pixel)
    );

    convolution #(.PIXEL_SIZE(PIXEL_SIZE), .ROW_SIZE(ROW_SIZE)) perform_convolution (
        .clk(clk),
        .rst_n(rst_n),
        .pixel(gray_pixel),
        .filter(input_filter),
        .output_pixel(convoluted_pixel)
    );

    absolute_value #(.PIXEL_SIZE(PIXEL_SIZE)) absoluter (
        .clk(clk),
        .rst_n(rst_n),
        .pixel(convoluted_pixel),
        .outPixel(output_pixel)
    );
 
endmodule