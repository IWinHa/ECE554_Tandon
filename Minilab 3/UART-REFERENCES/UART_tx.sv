module UART_tx(
	input clk,
	input rst_n,
	input trmt, // Asserted to initiate transmission
	input [7:0] tx_data, // Byte to transmit
	output reg tx_done, // Asserted when done, stays HIGH until next byte transmitted
	output reg TX
);

	/* ALL intermediary values */

	reg init; // Specifies that we are in GO state

	wire shift; // This will be asserted when the baud count hits 32 
				// and we need to shift the shift register by 1 bit

	reg transmitting; // Used to control when the counters are counting
					  // (if it is high, count; otherwise don't)

	reg [5:0] baud_cnt; // Counts the number of clock cycles there has been.
						// Intended to count to 32 (33 total, since 0 is its own cycle)

	reg [3:0] bit_cnt; // Counts the number of bits that we have shifted through
					   // Intended to count to 10 (1 start bit, 8 bits of data, 1 end bit)
	
	wire countedTo10; // Will later be assigned to bit_cnt === 10
					  // Essentially just there to make code more readable		

	reg [8:0] tx_shft_reg; // Holds 9 bits of actual data
						   // We know the STOP bit will be a 1,
						   // so we can shift a 1 in rather than have a 10 bit register

	reg set_done; // Used to assert when we have transmitted all of the data

	/* Baud counter */
	always_ff @(posedge clk)
		// If init is 1, then we are just starting so baud_cnt should be reset
		// If shift is 1, then we just hit 32 so we need to reset back to 0
		if (init | shift) baud_cnt <= 6'b0;
		else
			// If we are transmitting, then we increment.
			// Otherwise we just hold the value
			if (transmitting) baud_cnt <= baud_cnt + 1'b1;
	
	// If baud count hits 32, then we need to shift
	assign shift = (baud_cnt === 6'd32);


	/* Bit counter */
	always_ff @(posedge clk)
		// If init is 1, then we are just starting so we need to reset
		if (init) bit_cnt <= 4'b0;
		else
			// If shift is true, then we have shifted one more bit.
			// Otherwise, just hold the value.
			if (shift) bit_cnt <= bit_cnt + 1'b1;

	// This is just there because I feel countedTo10 is more readable
	// than having bit_cnt === 10 all over the place :)
	assign countedTo10 = (bit_cnt === 4'd10);


	/* Data shifter */
	always_ff @(posedge clk, negedge rst_n)
		// Since we are inactive at all 1s, we reset to all 1s in the shift register
		if (!rst_n) tx_shft_reg <= '1;
		else
			// If init is true, then it's time to load the value into the register
			// We go least significant bit first to most significant bit
			//  1'b0 is the START bit, indicating we are about to transmit
			if (init) tx_shft_reg <= {tx_data, 1'b0};
			else
				// If shift is true, then it's been 32 clock cycles at this bit.
				// Thus we need to shift right to the next bit.
				// A 1'b1 bit is used so that when we are done, the register
				// is already back at 1111_1111 (or inactive)
				if (shift) tx_shft_reg <= {1'b1, tx_shft_reg[8:1]};

	// TX will just be the least significant bit of the shift register.
	// We start by applying 1'b0 to it, and then shift each bit into 
	// the shift register's LSB so that TX will be its value for 32 clocks.
	assign TX = tx_shft_reg[0];


	/* Flip flop that handles DONE logic*/
	always_ff @(posedge clk, negedge rst_n)
		// On reset, we are not done
		if (!rst_n) tx_done <= 1'b0;
		else
			// If set_done is true, then we are done, so tx_done should be 1 
			if (set_done) tx_done <= 1'b1;
			else
				// If init is true, then we are starting again, so we deassert tx_done
				// Otherwise tx_done just holds its previous value 
				if (init) tx_done <= 1'b0;


	/* The "brains" of the operation (FSM) */

	// Define the two states we will use
	typedef enum reg {IDLE, TRANSMIT} STATES;

	STATES state, next_state;

	/* Flop for state */
	always_ff @(posedge clk, negedge rst_n)
		// Default to IDLE state
		if (!rst_n) state <= IDLE;
		// Otherwise take on the new state value at the pos clock edge
		else state <= next_state;	


	/* The actual state machine*/
	always_comb begin

		// Default inputs
		init = 0;
		set_done = 0;
		transmitting = 0;

		case (state)

			TRANSMIT: begin
				// if we have counted to 10, then we are done, so set_done
				set_done = countedTo10;
				// We are transmitting until we have counted to 10
				// (since once we hit 10, we are done)
				transmitting = ~countedTo10;
				// If we've counted to 10, then we are done transmitting.
				// Thus go back to IDLE, otherwise stay in TRANSMIT.
				next_state = countedTo10 ? IDLE : TRANSMIT;
			end

			// Same as IDLE
			// If for some reason state is not 0 or 1, 
			// it will do the same as IDLE state
			default: begin
				// As soon as trmt goes high, start init
				init = trmt;
				// If trmt goes high, it's transmitting time!
				// Otherwise just sit in IDLE
				next_state = (trmt) ? TRANSMIT : IDLE;
			end
				
		endcase
	end

endmodule
