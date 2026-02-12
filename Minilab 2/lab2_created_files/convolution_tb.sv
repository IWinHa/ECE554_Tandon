module convolution_tb();
    parameter ROW_SIZE = 1280;
    parameter PIXEL_SIZE = 12;
    parameter NUM_COLS = 100;
    parameter NUM_PIXELS = ROW_SIZE * NUM_COLS;
    parameter PRINT_INTERVAL = 100;

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

    string INPUT_FILE = "../ECE554_Tandon/Minilab 2/lab2_created_files/created_hex.hex";
    string OUTPUT_FILE = "../ECE554_Tandon/Minilab 2/lab2_created_files/written_data.hex";

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        input_pixel = '0;
        input_filter = '{'{-1, 0, 1}, '{-2, 0, 2}, '{-1, 0, 1}};

        @(negedge clk);

        $readmemh(INPUT_FILE, MEMORY);

        out_file = $fopen(OUTPUT_FILE, "w");

        rst_n = 1'b1;

        repeat (20) @(negedge clk);

        for (integer i = 0; i < NUM_PIXELS; i = i + 1) begin
            @(negedge clk);
            input_pixel = MEMORY[i];
            if (i % NUM_PIXELS == 0) $display("ITERATION %0d...", i);
            @(posedge clk);
        end

        $display("FINISHED DUMPING");
        $fclose(out_file);
        $stop();
    end

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (rst_n && (output_pixel[7:0] !== 8'hxx)) $fwrite(out_file, "%H\n", output_pixel[7:0]);
    end
endmodule