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

    end

    always #5 clk = ~clk;

endmodule