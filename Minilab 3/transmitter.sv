module transmitter(
    input clk,
    input reset,
    input baud_rate_generator, 
    input transmit_enable,  // For transmitter to start, this and baud_rate_generator must go high
                            // TODO: Do we want transmit_enable to have to be asserted before ANY bit shift?
                            // (i.e. it has to go high every time we want to shift along with baud_rate_generator)
                            // Currently the code only checks for transmit_enable to start transmitting
    input [7:0] transmit_buffer, // Data from DATABUS
    output reg TBR, // 1 if we can accept a transmit currently, 0 if we cannot
    output reg TxD  // The data we are sending bit by bit
);


    /* 
        LOGIC (at least in my head)
        start_transmitting should tell us when to start sending one bit at a time
        After that, take whatever was in the buffer and send it big by bit.
        Counter helps count 8 bits so we know when we are done.
    */

    reg [7:0] theBuffer;
    reg [7:0] toTransmit;

    // shift tells both counter to increment and toTransmit to move to the next bit
    reg shift;

    // Set ets everything ready for another transaction
    reg set;

    reg [3:0] counter; // Counts up to 8 to know how many cycles to wait before switching

    // Reset counter down to 0
    reg baud_reset;

    // Counter flop logic
    always_ff @(posedge clk)
        if (baud_reset | reset) counter <= 4'h0;
        else if (shift) counter <= counter + 1'b1;

    // Transmitter logic (both shifting and TxD)
    always_ff @(posedge clk)
        if (reset) begin
            // RESET: Start ready to transmit and accept whatever is currently in the buffer
            toTransmit <= theBuffer;
            TxD <= 1'b1;
        end
        else if (set) begin
            // Starting new transaction: Have TxD deasserted to indicate start of transaction
            toTransmit <= theBuffer;
            TxD <= 1'b0;
        end
        else if (shift) begin
            // Shift: move to the next bit
            toTransmit <= {1'b0, toTransmit[7:1]};
            TxD <= toTransmit[0];
        end

    // Buffer logic (works on CLK)
    always_ff @(posedge clk) begin
        if (reset) begin
            theBuffer <= 8'h00;
        end
        else if (transmit_enable) begin
            theBuffer <= transmit_buffer;
        end
    end

    // State Machine for transmitting
    // WAIT is where we wait for transmit_enable to go high (indicating start transmitting)
    // START is when we temporarily delay for the next baud_rate since we have to have 0 transmitted for 1 baud rate
    // TRANSMIT is when we actually transmit data
    typedef enum reg [1:0] {
        WAIT,
        START,
        TRANSMIT
    } state_t;

    state_t state, next_state;

    // State logic
    always_ff @(posedge clk)
        if (reset) state <= WAIT;
        else state <= next_state;

    always_comb begin
        // Default to avoid latches
        next_state = state;
        set = 1'b0;
        shift = 1'b0;
        TBR = 1'b0;
        baud_reset = 1'b0;

        case (state)
            START: begin
                // Wait for next baud_rate_generator before transmitting
                next_state = (baud_rate_generator) ? TRANSMIT : START;
                shift = baud_rate_generator;
            end

            TRANSMIT: begin
                // Transmit after every baud_rate
                // Move back to WAIT after counter = 8
                shift = ~(counter == 4'h8) & baud_rate_generator;
                next_state = (counter == 4'h8) ? WAIT : TRANSMIT;
            end

            // Same as WAIT
            default: begin 
                // Wait for transmit_enable and baud_rate_generator to BOTH go high
                next_state = (transmit_enable & baud_rate_generator) ? START : WAIT;
                TBR = ~(baud_rate_generator & transmit_enable);
                set = transmit_enable & baud_rate_generator;
                baud_reset = transmit_enable & baud_rate_generator;
            end
        endcase
    end


endmodule