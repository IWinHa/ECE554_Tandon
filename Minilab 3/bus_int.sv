module bus_interface(
    inout [7:0] DATABUS,
    input [7:0] rec_buffer,
    input [1:0] IOADDR,
    input RDA,
    input TBR,
    input IOCS,
    input IOR_W,
    output [7:0] trans_buffer,
    output trans_control,
    output receive_control
);

    // https://stackoverflow.com/questions/40902637/how-to-write-to-inout-port-and-read-from-inout-port-of-the-same-module


    // When IO_W is HIGH, we are writing - so DATABUS will be set to rec_buffer
    // When IO_R is LOW, we are reading
    always_comb begin
        case (IOADDR)
            2'b00: DATABUS = (IOR_W) ? rec_buffer : 8'bz;
            2'b01: DATABUS = {6'b0, TBR, RDA};
            default: DATABUS = 8'bz; // TODO: Coordinate what needs to be sent for DB Low/High
        endcase
    end

    assign trans_control = ((IOADDR == 2'b00) && IOR_W);
    assign receive_control = ((IOADDR == 2'b00) && ~IOR_W);
    assign trans_buffer = ((IOADDR == 2'b00) && IOR_W) ? DATABUS : 8'b0;

endmodule