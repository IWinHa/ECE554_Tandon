module bayer_generator #(
    parameter PIXEL_SIZE = 12
) (
    input clk,
    input rst_n,
    input [PIXEL_SIZE-1:0] pixel_from_queue,
    input [PIXEL_SIZE-1:0] pixel_raw
    output [PIXEL_SIZE-1:0] pixel_out
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

    // >> 2 should divide by 4
    assign pixel_out = (temp_pixels[0] + temp_pixels[1] + temp_pixels[2] + temp_pixels[3]) >> 2;

endmodule