module row_buffer #(
    parameter ROW_SIZE = 1280,
    parameter PIXEL_SIZE = 12
) (
    input clk,
    input rst_n,
    input [PIXEL_SIZE-1:0] pixel,
    output [PIXEL_SIZE-1:0] buffered_pixel
);

    reg [PIXEL_SIZE-1:0] stored_row [ROW_SIZE-1:0];

    always_ff @(posedge clk) begin
        buffered_pixel <= stored_row[ROW_SIZE - 1];
        stored_row <= '{stored_row, pixel};
    end

endmodule