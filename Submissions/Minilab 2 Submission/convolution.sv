module convolution #(
    parameter PIXEL_SIZE = 12,
    parameter ROW_SIZE = 640
)
(
    input clk,
    input rst_n,
    input [PIXEL_SIZE-1:0] pixel,
    input signed [PIXEL_SIZE-1:0] filter [0:2] [0:2],
    input valid_in,
    output reg signed [PIXEL_SIZE+5:0] output_pixel,
    output reg valid_out
);

    reg [PIXEL_SIZE-1:0] x [2:0][2:0];
    wire [PIXEL_SIZE-1:0] intermediatePixel [0:1];
    reg valid_mid;


    row_buffer #(.ROW_SIZE(ROW_SIZE), .PIXEL_SIZE(PIXEL_SIZE)) buffer [1:0] (
        .clk(clk), .rst_n(rst_n), .enable(valid_in), .pixel({pixel, intermediatePixel[0]}),
        .buffered_pixel({intermediatePixel[0], intermediatePixel[1]})
    );

    always_ff @(posedge clk) begin
        valid_out <= valid_in;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            for (integer i = 0; i <= 2; i = i + 1) begin
                for (integer j = 0; j <= 2; j = j + 1) begin
                    x[i][j] <= {PIXEL_SIZE{1'b0}};
                end
            end
        end
        else if (valid_in) begin
            x[2] <= '{x[2][1], x[2][0], intermediatePixel[1]};
            x[1] <= '{x[1][1], x[1][0], intermediatePixel[0]};
            x[0] <= '{x[0][1], x[0][0], pixel};
        end
    end

    always_comb begin
        output_pixel = '0;
        for (integer i = 0; i <= 2; i = i + 1) begin
            for (integer j = 0; j <= 2; j = j + 1) begin
                output_pixel = output_pixel + ($signed({1'b0, x[i][j]}) * filter[i][j]);
            end
        end

    end


endmodule