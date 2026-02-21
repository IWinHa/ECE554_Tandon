module receiver_tb();

    
    reg clk;
    reg reset;
    reg RxD;
    reg baud_rate_generator;
    wire [7:0] receiver_buffer;
    wire RDA;

    // Instantiate DUT
    receiver iDUT(.clk(clk), .reset(reset), .RxD(RxD), .baud_rate_generator(baud_rate_generator), 
                                .receiver_buffer(receiver_buffer), .RDA(RDA));

    // This will start baud_rate_generator to tick every GENERATOR_RATE seconds
    reg start_generator;

    // Approximate Baud Rate (in ns) - delayed by a few clock cycles as needed
    integer GENERATOR_RATE = 80;

    // Number of communications we will try to send
    integer NUM_ITERATIONS = 22;

    // Used internally for for loops.
    // They are declared here so we can track them in waveforms.
    integer iteration, i;

    // Holds the data we are going to transmit
    reg [7:0] data;

    initial begin
        $display("Begin Testing");

        // Initial Setup
        clk = 1'b0;
        reset = 1'b1;
        RxD = 1'b1;
        start_generator = 1'b0;
        baud_rate_generator = 1'b0;
        data = 8'h00;

        // Apply values
        @(posedge clk);

        // Deassert reset
        @(negedge clk);
        reset = 1'b0;
        @(posedge clk);

        // Let reset propagate and allow other time as needed
        repeat (10) @(negedge clk);

        if (RDA !== 1'b0) begin
            $display("ERROR (time %0d): RDA was not 0 after initialization", $time);
        end

        for (iteration = 0; iteration < NUM_ITERATIONS; iteration = iteration + 1) begin 
            // Start transmission! Changing on negative edge
            @(negedge clk);

            // Start baud_rate_generator
            start_generator = 1'b1;

            // We always start with RxD = 0 according to the SPART spec.
            // This also triggers receiver to start waiting for a signal
            RxD = 1'b0;

            // Gives data any 8 bit value
            data = $urandom_range(8'h00, 8'hFF);

            // Wait for RxD = 0 to propagate for one baud rate
            @(posedge baud_rate_generator);

            for (i = 0; i < 8; i = i + 1) begin
                // Transmit bit
                @(negedge clk);
                RxD = data[i];
                @(posedge clk);

                @(negedge clk);

                if (RDA !== 1'b0) begin
                    $display("ERROR (iteration %0d, time %0d): RDA was asserted while we are receiving", iteration, $time);
                end

                // Wait for baud rate before sending the next bit
                @(posedge baud_rate_generator);
            end
            repeat (2) @(negedge clk); // Wait enough for data to propagate

            // Check that received data was valid
            if (receiver_buffer !== data) begin
                $display("ERROR (iteration %0d, time %0d): data was %b but buffer had %b", iteration, $time, data, receiver_buffer);
            end
            if (RDA !== 1'b1) begin
                $display("ERROR (iteration %0d, time %0d): RDA was not asserted after receiving", iteration, $time);
            end

            // Reset RxD back to "IDLE", stop baud_rate_generator
            RxD = 1'b1;
            start_generator = 1'b0;

            // Wait arbitrary amount of time before next transmission
            repeat (20) @(negedge clk);
        end

        $display("End Testing");
        $stop();
    end

    always #5 clk = ~clk;

    // Baud Rate Generator
    always begin
        #(GENERATOR_RATE);

        // Once the specified amount of time has passed, start the generator on posedge clk
        @(posedge clk);
        if (start_generator) baud_rate_generator = 1'b1;

        // Assert for 1 cycle
        @(posedge clk);
        baud_rate_generator = 1'b0;
        @(posedge clk);
    end

endmodule