`default_nettype none
module FIFO
#(
  parameter DEPTH=8,
  parameter DATA_WIDTH=8  //will not work for log2 not integer
)
(
  input  wire clk,
  input  wire rst_n,
  input  wire rden,
  input  wire wren,
  input  wire [DATA_WIDTH-1:0] i_data,
  output reg [DATA_WIDTH-1:0] o_data,
  output logic full,
  output logic empty
);

  // Setup FIFO
  logic [DATA_WIDTH-1:0] fifo_mem [0:DEPTH-1];
  logic [$clog2(DEPTH):0] wr_ptr, rd_ptr; // Write and read pointers with 1 extra bit for full/empty detection

  assign full = ~((wr_ptr[$clog2(DEPTH)-1:0] ^ rd_ptr[$clog2(DEPTH)-1:0])) & (wr_ptr[$clog2(DEPTH)] != rd_ptr[$clog2(DEPTH)]); // Full when pointers differ in MSB only
  assign empty = ~|(wr_ptr ^ rd_ptr);

  // Output logic
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      o_data <= '0;
    end
    else begin
      if(rden & ~empty) begin
        o_data <= fifo_mem[rd_ptr[$clog2(DEPTH)-1:0]];
      end
      else begin
        o_data <= '0;
      end
    end
  end

  
  // FIFO logic (implemented as a circular buffer)
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr <= '0;
      rd_ptr <= '0;
    end
    else begin
      if(wren & ~full)  begin
        fifo_mem[wr_ptr] <= i_data;
        wr_ptr <= wr_ptr + 1;
      end
      if(rden & ~empty) begin
        rd_ptr <= rd_ptr + 1; 
      end
    end 

  end
  

endmodule