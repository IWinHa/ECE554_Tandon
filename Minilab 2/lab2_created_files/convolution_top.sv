module convolution_top #(
    parameter ROW_SIZE = 1280,
    parameter PIXEL_SIZE = 12
) (
    input clk,
    input rst_n,
    input [PIXEL_SIZE-1:0] input_pixel,
    input [10:0] x_cont,
    input [10:0] y_cont,
    input filter_type,
    input valid_in,
    output [PIXEL_SIZE-1:0] output_pixel,
    output valid_out
    // TODO: Add stuff here
);

    wire [PIXEL_SIZE-1:0] first_buffer_pixel;
    wire [PIXEL_SIZE-1:0] gray_pixel;
    wire signed [PIXEL_SIZE+3:0] convoluted_pixel;
    wire gray_valid, convoluted_valid;

    reg signed [PIXEL_SIZE-1:0] filter [-1:1] [-1:1];

    always_comb begin
        case (filter_type)
            1'b1: filter <= '{'{-1, 0, 1}, '{-2, 0, 2}, '{-1, 0, 1}};
            default: filter <= '{'{-1, -2, -1}, '{0, 0, 0}, '{1, 2, 1}};
        endcase

    end
    
    row_buffer #(.ROW_SIZE(ROW_SIZE), .PIXEL_SIZE(PIXEL_SIZE)) initial_buffer (
        .clk(clk),
        .rst_n(rst_n),
        .enable(valid_in),
        .pixel(input_pixel),
        .buffered_pixel(first_buffer_pixel)
    );

    bayer_generator #(.PIXEL_SIZE(PIXEL_SIZE)) convert_to_grayscale (
        .clk(clk),
        .rst_n(rst_n),
        .pixel_from_queue(first_buffer_pixel),
        .x_cont(x_cont),
        .y_cont(y_cont),
        .pixel_raw(input_pixel),
        .pixel_out(gray_pixel),
        .valid_in(valid_in),
        .valid_out(gray_valid)
    );

    convolution #(.PIXEL_SIZE(PIXEL_SIZE), .ROW_SIZE(ROW_SIZE / 2)) perform_convolution (
        .clk(clk),
        .rst_n(rst_n),
        .pixel(gray_pixel),
        .filter(filter),
        .output_pixel(convoluted_pixel),
        .valid_in(gray_valid),
        .valid_out(convoluted_valid)
    );

    absolute_value #(.PIXEL_SIZE(PIXEL_SIZE)) absoluter (
        .clk(clk),
        .rst_n(rst_n),
        .pixel(convoluted_pixel),
        .outPixel(output_pixel),
        .valid_in(convoluted_valid),
        .valid_out(valid_out)
    );
 
endmodule