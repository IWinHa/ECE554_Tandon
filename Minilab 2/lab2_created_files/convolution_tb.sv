
//  vsim -L C:/altera_lite/25.1std/questa_fse/intel/verilog/altera_mf -L C:/altera_lite/25.1std/questa_fse/intel/verilog/220model -vopt work.convolution_tb -voptargs=+acc

`timescale 1 ps / 1 ps

module convolution_tb();
    parameter ROW_SIZE = 1280;
    parameter PIXEL_SIZE = 12;
    parameter NUM_COLS = 500;
    parameter NUM_PIXELS = ROW_SIZE * NUM_COLS;
    parameter PRINT_INTERVAL = 100;

    reg clk;
    reg rst_n;
    reg [PIXEL_SIZE-1:0] input_pixel;
    reg input_filter;
    wire [PIXEL_SIZE-1:0] output_pixel;
    reg valid_in;
    wire valid_out;
    integer out_file;

    reg [PIXEL_SIZE-1:0] MEMORY [0:NUM_PIXELS];
    // TODO: Add stuff here

    reg [10:0] X_cont;
    reg [10:0] Y_cont;

    convolution_top #(.ROW_SIZE(ROW_SIZE), .PIXEL_SIZE(PIXEL_SIZE)) iDUT (
        .clk(clk),
        .rst_n(rst_n),
        .input_pixel(input_pixel),
        .filter_type(input_filter),
        .x_cont(X_cont),
        .y_cont(Y_cont),
        .output_pixel(output_pixel),
        .valid_in(valid_in),
        .valid_out(valid_out)
        // TODO: Add stuff here
    );

    string INPUT_FILE = "../ECE554_Tandon/Minilab 2/lab2_created_files/created_hex.hex";
    string OUTPUT_FILE = "../ECE554_Tandon/Minilab 2/lab2_created_files/written_data.hex";

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        input_pixel = '0;
        input_filter = 1'b0;
        valid_in = 1'b0;

        @(negedge clk);

        $readmemh(INPUT_FILE, MEMORY);

        out_file = $fopen(OUTPUT_FILE, "w");

        rst_n = 1'b1;

        repeat (20) @(negedge clk);

        for (integer i = 0; i < NUM_PIXELS; i = i + 1) begin
            @(negedge clk);
            valid_in = 1'b1;
            input_pixel = MEMORY[i];
            if (i % PRINT_INTERVAL == 0) $display("ITERATION %0d...", i);
            @(posedge clk);
        end

        $display("FINISHED DUMPING");
        $fclose(out_file);
        $stop();
    end

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (rst_n && (output_pixel[7:0] !== 8'hxx) && valid_out) begin
            if (output_pixel > 8'hFF) $fwrite(out_file, "%02H\n", 8'hFF);
            else $fwrite(out_file, "%02H\n", output_pixel[7:0]);
        end
    end

    always @(posedge clk) begin
        if (~rst_n) X_cont <= 11'b0;
        else if (X_cont == 1280) X_cont <= 0;
        else if (valid_in) X_cont <= X_cont + 1;
    end

    always @(posedge clk) begin
        if (~rst_n) Y_cont <= 11'b0;
        else if (Y_cont == 960) Y_cont <= 0;
        else if (valid_in)
            if (X_cont == 1280) Y_cont <= Y_cont + 1;
    end
endmodule