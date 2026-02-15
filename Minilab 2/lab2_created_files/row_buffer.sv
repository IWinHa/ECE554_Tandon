module row_buffer #(
    parameter ROW_SIZE = 1280,
    parameter PIXEL_SIZE = 12
) (
    input clk,
    input rst_n,
    input enable,
    input [PIXEL_SIZE-1:0] pixel,
    output reg [PIXEL_SIZE-1:0] buffered_pixel
);

    buffer_IP_640 store_data_640 (
        .aclr(~rst_n),
	    .clock(clk),
        .clken((ROW_SIZE == 640) ? enable : 1'b0),
	    .shiftin(pixel),
	    .shiftout(buffered_pixel_640),
	    .taps()
        
    );

    buffer_IP_1280 store_data_1280 (
        .aclr(~rst_n),
	    .clock(clk),
        .clken((ROW_SIZE == 640) ? 1'b0 : enable),
	    .shiftin(pixel),
	    .shiftout(buffered_pixel_1280),
	    .taps()
        
    );

    assign buffered_pixel = (ROW_SIZE == 640) ? buffered_pixel_640 : buffered_pixel_1280;

    // WITHOUT buffer_IP 

    /*
    reg [PIXEL_SIZE-1:0] stored_row [ROW_SIZE-1:0];

    always_ff @(posedge clk) begin
        if (enable) begin
            buffered_pixel <= stored_row[ROW_SIZE - 1];
            for (integer i = 1; i < ROW_SIZE; i = i + 1) begin
                stored_row[i] <= stored_row[i - 1];
            end
            stored_row[0] <= pixel;
        end
    end */

endmodule