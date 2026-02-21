module receiver(
    input clk,
    input reset,
    input RxD,
    input baud_rate_generator,
    output reg [7:0] receiver_buffer,
    output reg RDA
);

    // Counts up to 8 so we know when we have read enough bits
    reg [3:0] counter;
    reg counter_reset; // Resets counter back to 0

    // I was getting issues with RDA "blipping" after a successful read.
    // set_RDA helps control RDA to not glitch.
    reg set_RDA;

    // Buffer should shift right and counter should increment
    reg shift_enable;

    // Flop for buffer - reset as necessary and then shift the new bit in
    always_ff @(posedge clk)
        if (reset | counter_reset) receiver_buffer <= 8'h00;
        else if (shift_enable) receiver_buffer <= {RxD, receiver_buffer[7:1]};

    // Flop for counter - reset, increment
    always_ff @(posedge clk)
        if (reset | counter_reset) counter <= 4'h0;
        else if (shift_enable) counter <= counter + 1'b1;


    // States for the state machine
    // WAIT is while the receiver waits for transmission to start
        // (starts as soon as RxD goes down to 0)

    // RECEIVE is when the state machine is reading and shifting data
    typedef enum reg [1:0] {
        WAIT,
        RECEIVE
    } state_t;

    state_t state, next_state;

    // State flop
    always_ff @(posedge clk)
        if (reset) state <= WAIT;
        else state <= next_state;

    // RDA flop
    // Again, set_RDA is used to avoid "blipping" after a successful write.
    always_ff @(posedge clk)
        if (reset | counter_reset) RDA <= 1'b0;
        else if (set_RDA) RDA <= 1'b1; 


    // State machine
    always_comb begin
        // Default Parameters (avoids latches)
        counter_reset = 1'b0;
        shift_enable = 1'b0;
        set_RDA = 1'b0;

        case (state)
            RECEIVE: begin 
                // Once counter hits 8, wait until baud_rate_generator and then we are done!
                // Otherwise, we need to increment the counter and wait for the next bit
                set_RDA = (counter == 4'h8 & baud_rate_generator);
                next_state = (counter == 4'h8 & baud_rate_generator) ? WAIT : RECEIVE;
                shift_enable = (counter != 4'h8 & baud_rate_generator);
            end

            // Same as WAIT
            default: begin 
                // Wait for RxD to go low, indicating start of transmission
                next_state = (~RxD) ? RECEIVE : WAIT;
                counter_reset = ~RxD;
            end
        endcase
    end

endmodule