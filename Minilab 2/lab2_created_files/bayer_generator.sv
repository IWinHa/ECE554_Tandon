module bayer_generator #(
    parameter PIXEL_SIZE = 12
) (
    input clk,
    input rst_n,
    input [PIXEL_SIZE-1:0] pixel_from_queue,
    input [PIXEL_SIZE-1:0] pixel_raw,
    input [10:0] x_cont,
    input [10:0] y_cont,
    input valid_in,
    output [PIXEL_SIZE-1:0] pixel_out,
    output reg valid_out
);

    reg [PIXEL_SIZE-1:0] temp_pixels [0:3];

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin 
            for (integer i = 0; i < 4; i = i + 1) temp_pixels[i] <= {PIXEL_SIZE{1'b0}};
        end
        else begin
            temp_pixels[0] <= pixel_from_queue;
            temp_pixels[1] <= temp_pixels[0];
            temp_pixels[2] <= pixel_raw;
            temp_pixels[3] <= temp_pixels[2];
        end
    end

    always_ff @(posedge clk) 
        valid_out <= (x_cont[0] | y_cont[0]) ? 1'b0 : valid_in;

    // >> 2 should divide by 4
    wire [PIXEL_SIZE+2:0] sum = temp_pixels[0] + temp_pixels[1] + temp_pixels[2] + temp_pixels[3];
    assign pixel_out = sum >> 2;

endmodule