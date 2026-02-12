module convolution_tb();
    parameter ROW_SIZE = 1280;
    parameter PIXEL_SIZE = 12;
    parameter NUM_COLS = 5;
    parameter NUM_PIXELS = ROW_SIZE * NUM_COLS;

    reg clk;
    reg rst_n;
    reg [PIXEL_SIZE-1:0] input_pixel;
    reg signed [PIXEL_SIZE-1:0] input_filter [-1:1] [-1:1];
    wire [PIXEL_SIZE-1:0] output_pixel;
    integer out_file;

    reg [PIXEL_SIZE-1:0] MEMORY [0:NUM_PIXELS];
    // TODO: Add stuff here

    convolution_top #(.ROW_SIZE(ROW_SIZE), .PIXEL_SIZE(PIXEL_SIZE)) iDUT (
        .clk(clk),
        .rst_n(rst_n),
        .input_pixel(input_pixel),
        .input_filter(input_filter),
        .output_pixel(output_pixel)
        // TODO: Add stuff here
    );

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        input_pixel = '0;
        input_filter = '{'{-1, 0, 1}, '{-2, 0, 2}, '{-1, 0, 1}};

        @(negedge clk);

        $readmemh("to_read.hex", MEMORY);

        out_file = $fopen("written_data.hex", "w");

        repeat (20) @(negedge clk);

        for (integer i = 0; i < NUM_PIXELS; i = i + 1) begin
            @(negedge clk);
            input_pixel = MEMORY[i];
            @(posedge clk);
        end

    end

    always #5 clk = ~clk;

    always @(posedge clk) begin
        $fwrite(out_file, output_pixel);
    end
endmodule