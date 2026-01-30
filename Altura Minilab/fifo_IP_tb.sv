
`timescale 1 ps / 1 ps

module fifo_IP_tb();

    logic clk;
    logic rst_n;
    logic rden;
    logic wren;
    logic [7:0] i_data;
    logic [7:0] o_data;
    logic full;
    logic empty;

    int failed = 0;
    int total = 0;

    //  vsim -L C:/intelFPGA_lite/24.1std/questa_fse/intel/verilog/altera_mf -L C:/intelFPGA_lite/24.1std/questa_fse/intel/verilog/220model -vopt work.fifo_IP_tb -voptargs=+acc
    //Instantiate DUT

FIFO_IP iDUT (
	.data(i_data),
	.rdclk(clk),
	.rdreq(rden),
	.wrclk(clk),
	.wrreq(wren),
	.q(o_data),
	.wrfull(full),
	.rdempty(empty),
    .aclr(~rst_n)
);

initial begin
    rst_n = 0;
    clk = 0;
    rden = 0;
    wren = 0;
    i_data = 8'h01;

    @(negedge clk);
    rst_n = 1;


    if(empty !== 1) begin
        $display("Test failed at reset: expected empty=1, got %b", empty);
        failed++;
        total++;
    end

    if(full !== 0) begin
        $display("Test failed at reset: expected full=0, got %b", full);
        failed++;
        total++;
    end

    //Fill the buffer
    for (int i = 0; i < 8; i++) begin
        @(negedge clk);
        i_data = 8'h01 << i;
        wren = 1;

        // Check full flag
        @(posedge clk);
        wren = 0;
        @(negedge clk);
        total++;
        if ((i != 7) && full) begin
            failed++;
        end
    end

    @(negedge clk);
    total++;
    if(full !== 1) begin
        $display("Test failed at full check: expected full=1, got %b", full);
        failed++;
    end

    @(negedge clk);
    //Empty the buffer
    for (int i = 0; i < 8; i++) begin
        rden = 1;

        @(posedge clk);
        rden = 0;
        @(negedge clk);
        total++;
        total++;
        if (o_data !== (8'h01 << i)) begin
            $display("Test failed at read %0d: expected o_data=%h, got %h", i, (8'h01 << i), o_data);
            failed++;
        end

        // Check empty flag
        if ((i != 7) && empty) begin
            failed++;
        end
    end

    @(negedge clk);
    total++;
    if(empty !== 1) begin
        $display("Test failed at empty check: expected empty=1, got %b", empty);
        failed++;
    end 

    @(negedge clk);

    if (failed == 0)
        $display("Yahoo!! All tests passed! %0d/%0d", total, total);
    else
        $display("%0d/%0d tests failed. Back to the mines...", failed, total);
    $stop;
end

always #5 clk <= ~clk;


endmodule
