`default_nettype none

// Matrix-vector multiplier
module matvec_mult (
    input wire clk,
    input wire rst_n,
    input wire Clr,
    input wire start,
    output logic done,
    output logic [23:0]results[0:7] //8 results, each 24 bits wide
);

logic all_fifos_full, all_fifos_empty;
logic start_filler;
logic memory_busy;

logic matrix_fill_status[0:7], matrix_empty_status[0:7];
logic vector_fill_status, vector_empty_status;

logic [7:0]FIFO_fill_data;

logic [8:0]fifo_addr; //raw one hot encoding from memory interfacer
logic fifo_addr_conv[7:0];
logic fifo_addr_conv_vec;

logic [7:0]FIFO_data_matrix[0:7];
logic [7:0]FIFO_data_vector;

logic [7:0] B_shift_reg[0:7]; //8 wide shift (8x8) register for B inputs to MACs

reg [8:0] MAC_enables; //one enable per MAC unit (but add 8 bit depth to simplify shift register)
wire MAC_enables_conv[7:0];
wire VEC_enable;
logic clr_mac_en;

//state machine states
typedef enum logic [1:0] {
    IDLE,
    FILL,
    COMPUTE,
    DONE
} state_t;
state_t current_state, next_state;

assign all_fifos_full   = &{matrix_fill_status[7], matrix_fill_status[6], matrix_fill_status[5], matrix_fill_status[4], matrix_fill_status[3], matrix_fill_status[2], matrix_fill_status[1], matrix_fill_status[0], vector_fill_status};
assign all_fifos_empty  = &{matrix_empty_status[7], matrix_empty_status[6], matrix_empty_status[5], matrix_empty_status[4], matrix_empty_status[3], matrix_empty_status[2], matrix_empty_status[1], matrix_empty_status[0], vector_empty_status};

// memory interfacer which will spit out one 
// byte at a time to the FIFO's instantiated further down
// encoding is one hot for the FIFOs
fill_from_mem iFIFOFILLER (
    .clk(clk),
    .rst_n(rst_n),
    .addr(32'h0000_0000),        //starting address for matrix/vector data in memory
    .fill(start_filler),        //input to start filling process
    .fifoEnable(fifo_addr),      //one hot encoding (fifo address basically)
    .dataByte(FIFO_fill_data),  //one byte output from memory to FIFO's
    .memory_busy(memory_busy),   //output of memory controller
    .done( )                     //done signal from filler (not used here
);
// Above module is in progress so final ports may differ

//Convert our busses into arrays for easier indexing
genvar i;
generate    // convert fifo_addr for filling matrix FIFOs
    for(i=0; i<8; i=i+1) begin : ADDR_CONV_LOOP
        assign fifo_addr_conv[i] = fifo_addr[i] & (current_state == FILL);
    end
endgenerate

//Convert fifo_addr for filling vector FIFO
assign fifo_addr_conv_vec = fifo_addr[8] & (current_state == FILL);

genvar j;
generate    // convert MAC enables for MAC units; MAC enables are the same as the read enables for matrix FIFOs
    for(j=0; j<8; j=j+1) begin : MAC_EN_CONV_LOOP
        assign MAC_enables_conv[j] = MAC_enables[j];
    end
endgenerate

assign VEC_enable = MAC_enables[8]; //vector FIFO read enable is the same as the first MAC/FIFO read enable



//Instantiate FIFOs for matrix and vector storage (9 total)
FIFO matrix_fifo[0:7] (
    .clk(clk),
    .rst_n(rst_n),
    .rden(MAC_enables_conv),            //read enable from MAC unit
    .wren(fifo_addr_conv),            //write enable from memory interfacer [7:0]fifo_addr  fifo_addr[0:7]
    .i_data(FIFO_fill_data),         //data from memory interfacer
    .o_data(FIFO_data_matrix),         //data to MAC unit
    .full(matrix_fill_status), //one per FIFO
    .empty(matrix_empty_status)  //one per FIFO
);

FIFO vector_fifo (
    .clk(clk),
    .rst_n(rst_n),
    .rden(VEC_enable),            //read enable from MAC unit
    .wren(fifo_addr_conv_vec),            //write enable from memory interfacer
    .i_data(FIFO_fill_data),         //data from memory interfacer
    .o_data(FIFO_data_vector[7:0]),         //data to MAC unit
    .full(vector_fill_status),
    .empty(vector_empty_status)
);


//Instantiate MACs (8 total)
//B inputs propagate with enable signals shifted down the line
MAC iMAC[0:7](
    .clk(clk),
    .rst_n(rst_n),
    .En(MAC_enables_conv), //from state machine
    .Clr(Clr),
    .Ain(FIFO_data_matrix),  //from matrix FIFO 0
    .Bin(B_shift_reg),     //from vector FIFO (8 bit bus, 8 values)
    .Cout(results)         //to next MAC (each output is 24 bits wide)
);


//MAC enable and B input shift register chaining logic
always_ff @(posedge clk) begin
    if(clr_mac_en) begin
        MAC_enables <= 9'h000; //disable all MACs
        B_shift_reg <= '{default: 8'h00}; //clear shift register
    end
    else begin
        MAC_enables <= {1'b1, MAC_enables[8:1]}; //shift left enables
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
            
            if(all_fifos_full)
                next_state = COMPUTE;
            else
                next_state = FILL;
        end

        COMPUTE: begin
            clr_mac_en = 1'b0; //enable MACs
            if(Clr)
                next_state = IDLE;
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