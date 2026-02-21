module transmitter_tb();

    integer NUM_ITERATIONS = 15;

    reg clk;
    reg reset;
    reg baud_rate_generator;
    reg transmit_enable;    
    reg [7:0] transmit_buffer; // Data from DATABUS
    wire TBR; 
    wire TxD;

    // Starts baud_rate_generator
    reg start_generator;

    // (Approximate) rate the baud rate generator goes at
    integer GENERATOR_RATE = 80;

    // Instantiate DUT
    transmitter iDUT(.clk(clk), .reset(reset), .baud_rate_generator(baud_rate_generator), 
                        .transmit_enable(transmit_enable),
                        .transmit_buffer(transmit_buffer), .TBR(TBR), .TxD(TxD));

    // Used in for loops - declared here so they can be selected in waveforms
    integer iteration, i;

    // TODO: Change reset to not be a synchronous reset according to driver.sv?

    initial begin
        $display("Begin Testing");

        // Initial signals
        clk = 1'b0;
        reset = 1'b1;
        start_generator = 1'b0;
        baud_rate_generator = 1'b0;
        transmit_enable = 1'b0;
        transmit_buffer = 8'h00;

        // Deassert reset
        @(posedge clk);
        @(negedge clk);
        reset = 1'b0;
        @(posedge clk);

        // Allow for some time to go by
        repeat (10) @(negedge clk);

        if (TBR !== 1'b1) begin
            $display("ERROR (time %0d): TBR wasn't set on initialization", $time);
        end

        for (iteration = 0; iteration < NUM_ITERATIONS; iteration = iteration + 1) begin
            // Ready to transmit! Change values on negative clock edge
            @(negedge clk);

            // Start baud_rate_generator, set transmit_buffer to a random value
            transmit_buffer = $urandom_range(8'h00, 8'hFF);
            transmit_enable = 1'b1;
            start_generator = 1'b1;

            @(negedge clk);

            // Wait for one baud_rate since we just have to send 0 for one baud_rate cycle
            @(posedge baud_rate_generator);

            @(posedge clk);
            @(negedge clk);

            if (TxD !== 1'b0) begin
                $display("ERROR (Iteration %0d, time %0d) TxD didn't drop after starting", iteration, $time);
            end

            if (TBR !== 1'b0) begin
                $display("ERROR (iteration %0d, time %0d): TBR wasn't deasserted while transmitting", iteration, $time);
            end

            for (i = 0; i < 8; i = i + 1) begin
                // Wait for the next baud_rate tick
                @(posedge baud_rate_generator);
                @(posedge clk);
                @(negedge clk);

                // Check to make sure outputted bit was correct
                if (TxD !== transmit_buffer[i]) begin
                    $display("ERROR (Iteration %0d, time %0d) expected %h but was %h when i=%0d", iteration, $time, transmit_buffer[i], TxD, i);
                end
                if (TBR !== 1'b0) begin
                    $display("ERROR (iteration %0d, time %0d): TBR wasn't deasserted while transmitting", iteration, $time);
                end
            end
            
            // Done, turn off enable and baud_rate_generator
            @(negedge clk);
            start_generator = 1'b0;
            transmit_enable = 1'b0;
            @(posedge clk);


            if (TBR !== 1'b1) begin
                $display("ERROR (iteration %0d, time %0d): TBR wasn't asserted after transmitting", iteration, $time);
            end

            // Allow arbitrary amount of time to go by
            repeat (10) @(negedge clk);
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