module mac_tb();

    /*
    module MAC #(parameter DATA_WIDTH = 8) (
        input clk,
        input rst_n,
        input En,
        input Clr,
        input [DATA_WIDTH-1:0] Ain,
        input [DATA_WIDTH-1:0] Bin,
        output reg [DATA_WIDTH*3-1:0] Cout
    );

    */

    parameter DATA_WIDTH = 8;
    parameter NUM_ITERATIONS = 226;

    reg flag;

    reg clk;
    reg rst_n;
    reg En;

    reg Clr;

    integer temp_val;

    reg [DATA_WIDTH-1:0] Ain;
    reg [DATA_WIDTH-1:0] Bin;
    reg [DATA_WIDTH*3-1:0] Cout;

    MAC #(.DATA_WIDTH(DATA_WIDTH)) iDUT (
	.clk(clk),
        .rst_n(rst_n),
        .En(En),
        .Clr(Clr),
        .Ain(Ain),
        .Bin(Bin),
        .Cout(Cout)
    );

    initial begin
        $display("Begin testing");
        
        flag = 1'b1;
        clk = 1'b1;
        rst_n = 1'b0;
        En = 1'b0;
        Clr = 1'b0;
        temp_val = 0;
        Ain = {(DATA_WIDTH-1){1'b0}};
        Bin = {(DATA_WIDTH-1){1'b0}};

        repeat (5) @(posedge clk);

        @(negedge clk);
        // Check that MAC doesn't accumulate when En is 0
        Ain = $urandom_range(0, 2 ** (DATA_WIDTH - 1) - 1);
        Bin = $urandom_range(0, 2 ** (DATA_WIDTH - 1) - 1);
        rst_n = 1'b1;
        Clr = 1'b0;
        En = 1'b0;
        @(posedge clk);
        @(negedge clk);
        if (Cout !== {(DATA_WIDTH - 1) {1'b0}}) begin
            $display("TEST FAILED: When En was 0, Cout wasn't all zeroes, it was %h", Cout);
            flag = 1'b0;
        end

        // Initial Check (used to check clr resets correctly)
        @(negedge clk);
        Clr = 1'b0;
        En = 1'b1;
        @(posedge clk);
        @(negedge clk);
        if (Cout !== Ain * Bin) begin
            $display("TEST FAILED: When adding A_val (%h) and B_val (%h), expected (%h) didn't match Cout (%h)", Ain, Bin, Ain * Bin, Cout);
            flag = 1'b0;
        end

        @(negedge clk);
        Clr = 1'b1;
        @(posedge clk);
        @(negedge clk);
        if (Cout !== {(DATA_WIDTH - 1) {1'b0}}) begin
            $display("TEST FAILED: When Clr was asserted, Cout wasn't all zeroes, it was %h", Cout);
            flag = 1'b0;
        end

        // Test adding
        for (integer i = 0; i < NUM_ITERATIONS; i = i + 1) begin
            @(negedge clk);
            Ain = $urandom_range(0, 2 ** (DATA_WIDTH - 1) - 1);
            Bin = $urandom_range(0, 2 ** (DATA_WIDTH - 1) - 1);
            Clr = 1'b0;
            En = 1'b1;
            @(posedge clk);
            temp_val += Ain * Bin;
            @(negedge clk);
            if (Cout !== temp_val) begin
                $display("TEST FAILED: When i was %0d, Expected was %0h, Actual was %h", i, temp_val, Cout);
                flag = 1'b0;
            end
	    En = 1'b0; // Otherwise the counter might increment in between changing loops
        end

        $display("End Testing");
        if (flag === 1'b0) $display("Some case failed, see above for output");
        else $display("All cases passed!");
        $stop();
    end 

    always #5 clk = ~clk;

endmodule
