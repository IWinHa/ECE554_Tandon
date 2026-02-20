module receiver_tb();

    reg clk;
    reg reset;
    reg RxD;
    reg baud_rate_generator;
    wire [7:0] receiver_buffer;
    wire RDA;

    receiver iDUT(.clk(clk), .reset(reset), .RxD(RxD), .baud_rate_generator(baud_rate_generator), 
                                .receiver_buffer(receiver_buffer), .RDA(RDA));

    reg start_generator;
    integer GENERATOR_RATE = 22;
    integer NUM_ITERATIONS = 22;

    reg [7:0] data;

    initial begin
        $display("Begin Testing");
        clk = 1'b0;
        reset = 1'b1;
        RxD = 1'b1;
        baud_rate_generator = 1'b0;
        data = 8'h00;

        @(posedge clk);
        @(negedge clk);
        reset = 1'b0;
        @(posedge clk);

        repeat (10) @(negedge clk);

        for (integer iteration = 0; iteration < NUM_ITERATIONS; iteration = iteration + 1) begin 
            @(negedge clk);
            RxD = 1'b0;
            data = $urandom_range(8'h00, 8'hFF);
            @(posedge clk);
            for (integer i = 0; i < 8; i = i + 1) begin
                @(negedge clk);
                RxD = data[i];
                @(posedge clk);
                @(negedge clk);
            end
            RxD = 1'b1;
            if (receiver_buffer !== data) begin
                $display("ERROR (iteration %0d, time %0d): data was %b but buffer had %b", iteration, $time, data, receiver_buffer);
            end
        end

        $display("End Testing");
        $stop();
    end

    always #5 clk = ~clk;

    always begin
        #(GENERATOR_RATE);
        @(negedge clk);
        if (start_generator) baud_rate_generator = 1'b1;
        @(posedge clk);
        @(negedge clk);
        baud_rate_generator = 1'b0;
        @(posedge clk);
    end
endmodule