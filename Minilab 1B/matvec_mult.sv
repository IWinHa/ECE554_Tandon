// `default_nettype none

// Matrix-vector multiplier
module matvec_mult (
    input logic clk,
    input logic rst_n,
    input logic Clr,
    input logic start,
    output logic done,
    output logic [23:0]result[0:7] //8 results, each 24 bits wide
);

logic all_fifos_full, all_fifos_empty;
logic start_filler;

logic matrix_fill_status[0:7], matrix_empty_status[0:7];
logic vector_fill_status, vector_empty_status;

logic [7:0]FIFO_data_matrix[0:7];
logic [7:0]FIFO_data_vector;

logic [7:0] B_shift_reg[0:7]; //8 wide shift (8x8) register for B inputs to MACs

reg [15:0] MAC_enables; //one enable per MAC unit (but add 8 bit depth to simplify shift register)
reg clr_mac_en;
reg memory_busy;

//state machine states
typedef enum logic [1:0] {
    IDLE,
    FILL,
    COMPUTE,
    DONE
} state_t;
state_t current_state, next_state;

assign all_fifos_full   = 1'b0; // &{matrix_fill_status, vector_fill_status};
assign all_fifos_empty  = 1'b0; // &{matrix_empty_status, vector_empty_status};

// memory interfacer which will spit out one 
// byte at a time to the FIFO's instantiated further down
// encoding is one hot for the FIFOs
feed_from_mem iFIFOFILLER (
    .clk(clk),
    .rst_n(rst_n),
    .fifo_addr(),       //one hot encoding
    .fifo_din(),        //one byte input
    .en_fifo_write(),
    .fill(start_filler),//input to start iFIFOFILLER
    .memory_busy()      //output of memory controller
);
// Above module is in progress so final ports may differ

//Instantiate FIFOs for matrix and vector storage (9 total)
FIFO matrix_fifo[0:7] (
    .clk(clk),
    .rst_n(rst_n),
    .rden(),            //read enable from MAC unit
    .wren(),            //write enable from memory interfacer
    .i_data(),         //data from memory interfacer
    .o_data(FIFO_data_matrix),         //data to MAC unit
    .full(matrix_fill_status), //one per FIFO
    .empty(matrix_empty_status)  //one per FIFO
);

FIFO vector_fifo (
    .clk(clk),
    .rst_n(rst_n),
    .rden(),            //read enable from MAC unit
    .wren(),            //write enable from memory interfacer
    .i_data(),         //data from memory interfacer
    .o_data(FIFO_data_vector[7:0]),         //data to MAC unit
    .full(vector_fill_status),
    .empty(vector_empty_status)
);


//Instantiate MACs (8 total)
//B inputs propagate with enable signals shifted down the line

MAC iMAC[0:7](
    .clk(clk),
    .rst_n(rst_n),
    .En(MAC_enables[15:8]), //from state machine
    .Clr(Clr),
    .Ain(FIFO_data_matrix),  //from matrix FIFO 0
    .Bin(B_shift_reg),     //from vector FIFO (8 bit bus, 8 values)
    .Cout(result)         //to next MAC (each output is 24 bits wide)
);


//MAC enable and B input shift register chaining logic
always_ff @(posedge clk) begin
    if(clr_mac_en) begin
        MAC_enables <= 16'h00FF; //disable all MACs
        B_shift_reg <= '{default: 8'h00}; //clear shift register
    end
    else begin
        MAC_enables <= {MAC_enables[14:0], 1'b0}; //shift left enables
        // Shift register: load new data from vector FIFO and shift existing data
        B_shift_reg[0] <= FIFO_data_vector;
        B_shift_reg[1] <= B_shift_reg[0];
        B_shift_reg[2] <= B_shift_reg[1];
        B_shift_reg[3] <= B_shift_reg[2];
        B_shift_reg[4] <= B_shift_reg[3];
        B_shift_reg[5] <= B_shift_reg[4];
        B_shift_reg[6] <= B_shift_reg[5];
        B_shift_reg[7] <= B_shift_reg[6];
    end
end

//State machine to control the overall operation of the matvec_mult unit
//States: IDLE, FILL, COMPUTE, DONE
always_ff @(posedge clk or negedge rst_n)
    if(!rst_n) 
        current_state <= IDLE;

    else
        current_state <= next_state;

always_comb begin
    //Default assignments
    next_state = current_state;
    start_filler = 1'b0;
    clr_mac_en = 1'b1; //default to clearing MAC enables
    done = 1'b0;
    

    case(current_state)
        IDLE: begin
            if(start)
                next_state = FILL;
            else
                next_state = IDLE;
        end

        FILL: begin
            //Wait for memory to not be busy
            if(!memory_busy) 
                start_filler = 1'b1;       
            else 
                if(all_fifos_full)
                    next_state = COMPUTE;
                else
                    next_state = FILL;
            next_state = FILL;  //stay in FILL until all FIFOs are full
        end

        COMPUTE: begin
            if(Clr) begin
                next_state = IDLE;
                clr_mac_en = 1'b0; //enable MAC en shifting
            end
            else if(all_fifos_empty)
                next_state = DONE;
            else
                next_state = COMPUTE;
        end

        DONE: begin
            done = 1'b1;
            if(Clr)
                next_state = IDLE;
            else
                next_state = DONE;
        end

        default: next_state = IDLE;
    endcase


end

endmodule