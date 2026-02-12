module row_buffer #(
    parameter ROW_SIZE = 1280,
    parameter PIXEL_SIZE = 12
) (
    input clk,
    input rst_n,
    input [PIXEL_SIZE-1:0] pixel,
    output reg [PIXEL_SIZE-1:0] buffered_pixel
);

    reg [PIXEL_SIZE-1:0] stored_row [ROW_SIZE-1:0];

    always_ff @(posedge clk) begin
        buffered_pixel <= stored_row[ROW_SIZE - 1];
        for (integer i = 1; i < ROW_SIZE; i = i + 1) begin
            stored_row[i] <= stored_row[i - 1];
        end
        stored_row[0] <= pixel;
    end

endmodule