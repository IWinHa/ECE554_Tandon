module convolution #(
    parameter PIXEL_SIZE = 12,
    parameter ROW_SIZE = 1280
)
(
    input clk,
    input rst_n,
    input [PIXEL_SIZE-1:0] pixel,
    input signed [PIXEL_SIZE-1:0] filter [-1:1] [-1:1],
    output reg [PIXEL_SIZE+2:0] output_pixel
);

    reg [PIXEL_SIZE-1:0] x [2:0][2:0];
    wire [PIXEL_SIZE-1:0] intermediatePixel [0:1];


    row_buffer #(.ROW_SIZE(ROW_SIZE), .PIXEL_SIZE(PIXEL_SIZE)) buffer [1:0] (
        .clk(clk), .rst_n(rst_n), .pixel({pixel, intermediatePixel[0]}),
        .buffered_pixel({intermediatePixel[0], intermediatePixel[1]})
    );

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            for (integer i = 0; i <= 2; i = i + 1) begin
                for (integer j = 0; j <= 2; j = j + 1) begin
                    x[i][j] <= {PIXEL_SIZE{1'b0}};
                end
            end
        end
        else begin
            x[2] <= '{x[2][1], x[2][0], intermediatePixel[1]};
            x[1] <= '{x[1][1], x[1][0], intermediatePixel[0]};
            x[0] <= '{x[0][1], x[0][0], pixel};
        end
    end

    always_comb begin
        output_pixel = {PIXEL_SIZE{1'b0}};
        for (integer i = 0; i <= 2; i = i + 1) begin
            for (integer j = 0; j <= 2; j = j + 1) begin
                output_pixel = output_pixel + ($signed(x[i][j]) * filter[i - 1][j - 1]);
            end
        end
    end


endmodule