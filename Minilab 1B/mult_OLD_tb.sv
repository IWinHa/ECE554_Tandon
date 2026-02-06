module mult_OLD_tb();

    parameter NUM_ITERATIONS = 10;

    reg [7:0] A [0:7] [0:7];
    reg [7:0] B [0:7];
    wire [23:0] actualC [0:7];
    wire [23:0] expectedC [0:7];
    reg [23:0] zeroedC [0:7] = {24'h0, 24'h0, 24'h0, 24'h0, 24'h0, 24'h0, 24'h0, 24'h0};
    reg start;
    wire done;
    reg clk;
    reg rst_n;
    reg Clr;

    reg failed;

    // TODO: Instantiate DUT
    matvec_mult iDUT (.clk(clk), .rst(rst_n), .Clr(Clr), .start(start), .done(done), .results(actualC));

    // Checker - see below
    matrix_mult expectedOutput(.A(A), .B(B), .C(expectedC), .clk(clk), .rst_n(rst_n));

    initial begin
        $display("Begin testing");

        // Reset Signals
        clk = 1'b0;
        rst_n = 1'b0;
        failed = 1'b0; // Innocent until proven guilty
        Clr = 1'b0;
        start = 1'b0;
        repeat (5) @(negedge clk);

        // Get ready for testing
        rst_n = 1'b1;
        @(negedge clk);
            
        // TODO: Reset MAC and FIFO (if needed)

        // Get new data for A and B
        @(negedge clk);
        for (integer x = 0; x < 8; x = x + 1) begin
            for (integer y = 0; y < 8; y = y + 1) begin
                A[x][y] = $urandom_range(0, (2 ** 8) - 1);
            end

            B[x] = $urandom_range(0, (2 ** 8) - 1);
        end

        // TODO: Insert data into FIFO/MAC

        @(posedge clk);
        @(negedge clk);

        // TODO: Wait for output to be ready

        @(negedge clk);

        if (expectedC !== actualC) begin
            $display("ERROR: expected didn't match actual (iteration %0d - time %0d ns)", iteration, $time);
            for (integer i = 0; i < 8; i = i + 1) begin
                if (expectedC[i] !== actualC[i]) $display("Index %0d didn't match, expected %0d but was %0d", 
                                i, $unsigned(expectedC[i]), $unsigned(actualC[i]));
            end
            failed = 1'b1;
        end

        // Test clear to make sure it works
        @(negedge clk);
        Clr = 1'b1;
        @(negedge clk);
        Clr = 1'b0;
        @(posedge clk);
        if (expectedC !== zeroedC) begin
            $display("ERROR: clear didn't actual clear");
            $display("Check time %0d", $time);
            failed = 1'b1;
        end

        $display("End testing");
        if (failed) $display("See output for fail details");
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

module matrix_mult(
    input [7:0] A [0:7][0:7],
    input [7:0] B [0:7],
    input clk,
    input rst_n,
    output reg [23:0] C [0:7]
);
    integer i, j;

    reg [23:0] temp;

    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 8; i = i + 1) begin
                C[i] <= 24'h0;
            end
        end
        else begin
            for (i = 0; i < 8; i = i + 1) begin
                temp = 24'h000000;
                for (j = 0; j < 8; j = j + 1) begin
                    temp = temp + (A[i][j] * B[j]);
                end
                C[i] = temp;
            end 
        end
    end

endmodule