module transmitter_tb();

    // TODO: Change away from start_transmitting

    integer NUM_ITERATIONS = 15;

    reg clk;
    reg reset;
    reg baud_rate_generator; // TODO: Finalize what is brought out of the transmitter
                                // My thought was this will be a clock-like signal but that may not be correct
    reg transmit_enable;    
    reg [7:0] transmit_buffer; // Data from DATABUS
    wire TBR; 
    wire TxD;

    reg start_generator;
    integer GENERATOR_RATE = 80;

    transmitter iDUT(.clk(clk), .reset(reset), .baud_rate_generator(baud_rate_generator), 
                        .transmit_enable(transmit_enable),
                        .transmit_buffer(transmit_buffer), .TBR(TBR), .TxD(TxD));

    integer iteration, i;

    // TODO: Change reset to not be a synchronous reset according to driver.sv

    initial begin
        $display("Begin Testing");
        clk = 1'b0;
        reset = 1'b1;
        start_generator = 1'b0;
        baud_rate_generator = 1'b0;
        transmit_enable = 1'b0;
        transmit_buffer = 8'h00;


        @(posedge clk);
        @(negedge clk);
        reset = 1'b0;
        @(posedge clk);

        repeat (10) @(negedge clk);

        for (iteration = 0; iteration < NUM_ITERATIONS; iteration = iteration + 1) begin
            @(negedge clk);
            transmit_buffer = $urandom_range(8'h00, 8'hFF);
            transmit_enable = 1'b1;
            @(posedge clk);
            @(negedge clk);
            transmit_enable = 1'b0;
            @(posedge clk);
            @(negedge clk);
            start_generator = 1'b1;
            @(negedge clk);
            @(posedge baud_rate_generator);

            @(posedge clk);
            @(negedge clk);
            // TODO: TxD should be 1'b0 here
            if (TxD !== 1'b0) begin
                $display("ERROR (Iteration %0d, time %0d) TxD didn't drop after starting", iteration, $time);
            end

            for (i = 0; i < 8; i = i + 1) begin
                @(posedge baud_rate_generator);
                @(posedge clk);
                @(negedge clk);
                if (TxD !== transmit_buffer[i]) begin
                    $display("ERROR (Iteration %0d, time %0d) expected %h but was %h when i=%0d", iteration, $time, transmit_buffer[i], TxD, i);
                end
            end
            @(negedge clk);
            start_generator = 1'b0;
            @(posedge clk);
            repeat (10) @(negedge clk);
        end

        $display("End Testing");
        $stop();
    end

    always #5 clk = ~clk;

    always begin
        #(GENERATOR_RATE);
        @(posedge clk);
        if (start_generator) baud_rate_generator = 1'b1;
        @(posedge clk);
        baud_rate_generator = 1'b0;
        @(posedge clk);
    end

endmodule