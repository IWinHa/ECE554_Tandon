module feed_from_mem_tb();

    parameter NUM_FIFOS=9;
    parameter DEPTH=8;
    parameter DATA_WIDTH=8;

    reg clk;
    reg rst_n;
    reg [31:0] addr;
    reg fill;
    wire [DATA_WIDTH-1:0] dataByte;
    wire [NUM_FIFOS-1:0] fifoEnable;

    reg [7:0] memory [0:7] [0:8];
    reg failed;



    feed_from_mem iDUT #(.NUM_FIFOS(NUM_FIFOS), .DEPTH(DEPTH), .DATA_WIDTH(DATA_WIDTH)) (
        // System Controls
        .clk(clk),
        .rst_n(rst_n),

        // User Controls to MEM
        .addr(addr),    // Address to fill FIFO from [31:0]

        // User Controls to FIFO
        .fill(fill),           // Initiate filling of FIFOs

        // Interface to FIFO
        .dataByte(dataByte),  // Data written to selected FIFO [DATA_WIDTH-1:0]
        .fifoEnable(fifoEnable)     // Write-Enable to FIFOs (1-hot) [NUM_FIFOS-1:0]
    );

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        addr = 32'h0000_0000;
        fill = 1'b0;
        failed = 1'b0; // Innocent until proven guilty
        $display("Loading ROM...");
        $readmemh("copied_memory.mem", memory);
        $display("ROM loaded, begin testing");
        
        repeat (5) @(negedge clk);
        rst_n = 1'b1;
        @(negedge clk);

        for (integer i = 0; i < memory.size; i = i + 1) begin
            for (integer j = 0; j < memory[0].size; j = j + 1) begin
                
                // Assert fill for 1 clock cycle
                @(negedge clk);
                fill = 1'b1;
                @(posedge clk);
                @(negedge clk);
                fill = 1'b0;
                @(posedge clk);

                // Wait until fifoEnable goes high (data should be ready then)
                @(posedge fifoEnable);
                if (dataByte !== memory[i][j]) begin
                    $display("ERROR: at time %0d, actual value of 0x%h didn't match expected 0x%h", dataByte, memory[i][j]);
                    failed = 1'b1;
                end
                @(negedge clk);
                addr = addr + 1'b1;
            end
        end

        $display("End of testing");
        if (failed) $display("See console for issues...");
        else $display("All cases passed!");
        $stop();
    end

    initial begin
        repeat (2000) @(negedge clk);
        $display("ERROR: TOO MANY CLOCK CYCLES PASSED...");
        $stop();
    end

    always #5 clk = ~clk;

endmodule