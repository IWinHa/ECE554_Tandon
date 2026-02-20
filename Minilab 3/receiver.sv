module receiver(
    input clk,
    input reset,
    input RxD,
    input baud_rate_generator,
    output reg [7:0] receiver_buffer,
    output reg RDA
);

    reg [3:0] counter;
    reg counter_reset;
    reg new_RDA;

    reg shift_enable;

    always_ff @(posedge clk)
        if (reset | counter_reset) receiver_buffer <= 8'hx;
        else if (shift_enable) receiver_buffer <= {RxD, receiver_buffer[7:1]};

    always_ff @(posedge clk)
        if (reset | counter_reset) counter <= 4'h0;
        else if (shift_enable) counter <= counter + 1'b1;


    typedef enum reg [1:0] {
        WAIT,
        RECEIVE
    } state_t;

    state_t state, next_state;

    always_ff @(posedge clk)
        if (reset) state <= WAIT;
        else state <= next_state;

    always_ff @(posedge clk)
        if (reset) RDA <= 1'b0;
        else RDA <= new_RDA;

    always_comb begin
        next_state = state;
        new_RDA = RDA;
        counter_reset = 1'b0;
        shift_enable = 1'b0;

        case (state)
            RECEIVE: begin 
                new_RDA = (counter == 4'h8);
                next_state = (counter == 4'h8) ? WAIT : RECEIVE;
                shift_enable = baud_rate_generator;
            end

            // Same as WAIT
            default: begin 
                next_state = (~RxD) ? RECEIVE : WAIT;
                new_RDA = (~RxD) ? 1'b0 : new_RDA;
                counter_reset = ~RxD;
            end
        endcase
    end

endmodule