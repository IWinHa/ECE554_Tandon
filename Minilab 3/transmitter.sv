module transmitter(
    input clk,
    input reset,
    input baud_rate_generator, // TODO: Finalize what is brought out of the transmitter
                                // My thought was this will be a clock-like signal but that may not be correct
    input transmit_enable,    
    input [7:0] transmit_buffer, // Data from DATABUS
    output reg TBR, 
    output reg TxD
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

    reg baud_reset;

    // Counter flop logic (based on baud rate?)
    always_ff @(posedge clk)
        if (baud_reset | reset) counter <= 4'h0;
        else if (shift) counter <= counter + 1'b1;

    // Transmitter logic (both shifting and TxD) (based on baud rate?)
    always_ff @(posedge clk)
        if (reset) begin
            toTransmit <= theBuffer;
            TxD <= 1'b1;
        end
        else if (set) begin
            toTransmit <= theBuffer;
            TxD <= 1'b0;
        end
        else if (shift) begin
            toTransmit <= {1'b0, toTransmit[7:1]};
            TxD <= toTransmit[0];
        end

    // Buffer logic (works on CLK)
    // TODO: Buffer based on clock or baud_rate_generator?
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
    typedef enum reg [1:0] {
        WAIT,
        START,
        TRANSMIT
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
        baud_reset = 1'b0;

        case (state)
            START: begin
                next_state = (baud_rate_generator) ? TRANSMIT : START;
                shift = baud_rate_generator;
            end

            TRANSMIT: begin
                shift = ~(counter == 4'h8) & baud_rate_generator;
                next_state = (counter == 4'h8) ? WAIT : TRANSMIT;
            end

            // Same as WAIT
            default: begin 
                next_state = (baud_rate_generator) ? START : WAIT;
                TBR = ~baud_rate_generator;
                set = baud_rate_generator;
                baud_reset = baud_rate_generator;
            end
        endcase
    end


endmodule