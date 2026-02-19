module UART_rx(
	input clk,
	input rst_n,
	input RX,
	input clr_rdy,
	output reg [7:0] rx_data,
	output reg rdy
);

	// Instantiate all signals
	reg start, shift, receiving;
	reg [3:0] bit_cnt;
	reg [5:0] baud_cnt;
	reg [8:0] rx_shft_reg;
	reg set_rdy;

	// Double Flop the RX input for metastability
	reg rx_1, rx_2;
	always_ff @(posedge clk, negedge rst_n)
		if (!rst_n) begin
			// RX is IDLE when it is at all 1s.
			// Thus the reset acts like a preset, setting to all 1s
			rx_1 <= '1;
			rx_2 <= '1;
		end
		else begin
			rx_1 <= RX;
			rx_2 <= rx_1;
		end


	// bit counter - counts the number of shifts we have made.
	// Once we hit 10 we are done with our operation.
	always_ff @(posedge clk)
		// Once start is asserted, we are, well, starting
		// We start by counting 0 bits
		if (start) bit_cnt <= 4'h0;
		else if (shift) bit_cnt <= bit_cnt + 1;
	
	
	// Intermediary signal that designates when we counted to 10.
	// It is included primarily to make code readability easier.
	wire countTo10 = (bit_cnt === 4'b10);


	// Baud counter - counts clock cycles
	always_ff @(posedge clk) begin
		// We want to sample in the middle of the baud count.
		// Thus at the very beginning we only count from 15.
		// After that we will be in the middle of the count,
		// so we should wait the full baud count.
		if (start) baud_cnt <= 6'd15;
		else if (shift) baud_cnt <= 6'd32;
		
		// This counter counts DOWN rather than up.
		else if (receiving) baud_cnt <= baud_cnt - 1;
	end
	
	// We need to shift a bit once baud_cnt hits 0.
	// |baud_cnt is 1 if ANY signal is 1.
	// Thus it only returns 0 if EVERY bit in baud_cnt is 0.
	// If we NOT it, then it returns 1 if EVERY bit is 0.
	assign shift = ~(|baud_cnt);

	// Rx_data shifter
	// rx_2 is used for metastability
	always_ff @(posedge clk) begin
		// Once we shift, we discard the LSB and shift the new bit into rx_shft_reg
		if (shift) rx_shft_reg = {rx_2, rx_shft_reg[8:1]};
	end
	
	// Assign the LSBs of rx_shft_reg to the received data
	// (the final bit is not part of rx_data)
	assign rx_data = rx_shft_reg[7:0];


	// Done flop
	always_ff @(posedge clk, negedge rst_n) begin
		// Upon startup, we are not ready
		if (!rst_n) rdy <= 1'b0;
		
		// set_rdy is asserted when we hit baud_cnt = 10.
		// Once we hit that, we are done, so assert ready
		else if (set_rdy) rdy <= 1'b1;
		
		// clr_rdy is a synchronous reset to knock down rdy.
		// If we start, then we also need to knock down rdy
		// because we are starting a new receive
		else if (start | clr_rdy) rdy <= 1'b0;
	end


	/* STATE MACHINE LOGIC */
	
	// The "proper" way to create states
	typedef enum reg {IDLE, RECEIVE} state_t;
	state_t state, nxt_state;

	// State Flop
	always_ff @(posedge clk, negedge rst_n)
		// On reset we are in the IDLE state
		if (!rst_n) state <= IDLE;
		else state <= nxt_state;
	
	
	// always comb block (the BRAINS)
	always_comb begin
	
		// Default inputs to avoid flops
		start = 0;
		set_rdy = 0;
		receiving = 0;
		nxt_state = state;
		
		// Create the state logic
		case (state)
		
			// We are in this state when data is being transmitted.
			RECEIVE: begin
				// We are receiving until we count to 10 bits received.
				// Once we have done that, the operation is complete.
				// We also then return to the IDLE state.
				receiving = ~countTo10;
				set_rdy = countTo10;
				nxt_state = (countTo10) ? IDLE : RECEIVE;
			end

			// SAME AS IDLE
			// In case state somehow becomes not 0 or 1,
			// it will behave like it was in the IDLE state.
			default: begin
				// We wait until RX drops, since that is the start bit.
				// However we use the flopped version for metastability.
				// Note that since RX is 1 bit, (RX === 0) is equivaent to ~RX
				start = ~rx_2;
				
				// Once the bit is 0, go to receive mode since that is the start bit
				nxt_state = (~rx_2) ? RECEIVE : IDLE;
			end
		endcase
	end

endmodule
