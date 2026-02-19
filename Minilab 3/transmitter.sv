module transmitter(
    input clk,
    input reset,
    input baud_rate_generator, // TODO: Finalize what is brought out of the transmitter
                                // My thought was this will be a clock-like signal but that may not be correct
    input start_transmitting, // TODO: When do we start transmitting through TxD? Are we having a signal to start it?
    input transmit_enable,    
    input [7:0] transmit_buffer, // Data from DATABUS
    output TBR, 
    output TxD
);


    /* 
        LOGIC (at least in my head)
        start_transmitting should tell us when to start sending one bit at a time
        After that, take whatever was in the buffer and send it big by bit.
        Counter helps count 8 bits so we know when we are done.
    */

    reg [7:0] theBuffer; // TODO: Is the buffer only size 1? Is the size configurable? If not 1, how does transmitting work?
    reg [7:0] toTransmit;
    reg shift;
    reg set;

    reg [3:0] counter; // Counts up to 8 to know how many cycles to wait before switching
    reg counter_enable;


    // Counter flop logic (based on baud rate?)
    always_ff @(posedge baud_rate_generator)
        if (reset) counter <= 4'h0;
        else if (counter_enable) counter <= counter + 1'b1;

    // Transmitter logic (both shifting and TxD) (based on baud rate?)
    always_ff @(posedge baud_rate_generator)
        if (reset) begin
            toTransmit <= 8'h00;
            TxD <= 1'b1;
        end
        else if (set) begin
            toTransmit <= theBuffer;
            TxD <= 1'b0;
        end
        else if (shift) begin
            toTransmit <= {toTransmit[6:0], 1'b0};
            TxD <= toTransmit[7];
        end
        else TxD <= 1'b1;

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
    // FIXME: Change back to [1:0] if 4 states are enough (not really a priority)
    typedef enum reg [2:0] {
        WAIT,
        START,
        TRANSMIT,
        STOP
    } state_t;

    state_t state, next_state;

    always_ff @(posedge clk)
        if (reset) state <= WAIT;
        else state <= next_state;

    always_comb begin
        // Default to avoid latches
        next_state = state;
        set = 1'b0;
        shift = 1'b0;
        TBR = 1'b1; // Start ready to transmit

        case (state)
            START: begin
                next_state = TRANSMIT;
                shift = 1'b1;
            end

            TRANSMIT: begin
                shift = ~(counter == 4'h8);
                next_state = (counter == 4'h8) ? WAIT : TRANSMIT;
            end

            // Same as WAIT
            default: begin 
                next_state = (start_transmitting) ? START : WAIT;
                TBR = ~start_transmitting;
                set = ~start_transmitting;
            end
        endcase
    end


endmodule