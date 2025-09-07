/*
a simple fifo
that does storage and forward when asked
cut through functionality will be added when parser is developed
cut through switching coding at the bottom

for axis_word_t consult axis_pkg.sv for reference , that package contains further details.
*/



import axis_pkg::*;

module axis_fifo #(
    parameter int data_width = 64,
    parameter int data_user  = 128,
    parameter int depth      = 8
)(
    input  logic       aclk,
    input  logic       aresetn,

    // write side
    input  logic       wr_en,
    input  axis_word_t wr_data,
    output logic       full,

    // read side
    input  logic       rd_en,
    output axis_word_t rd_data,
    output logic       empty
);

    // derived widths , clog2 is ceiling of the log , makes the process easier , doesnt need to hardocode
    localparam int ADDR_W  = $clog2(depth); //3
    localparam int COUNT_W = $clog2(depth+1); //4?

    // storage
    axis_word_t mem [depth-1:0]; //simple enough to explain

    // pointers & count
    logic [ADDR_W-1:0]  wptr, rptr;
    logic [COUNT_W-1:0] count;

    // status flags (cast depth to same width as count)
    assign empty = (count == '0);
    assign full  = (count == COUNT_W'(depth));

    // read data (outputs)
    assign rd_data = mem[rptr];

    // write part
    always_ff @(posedge aclk or negedge aresetn) begin : write_proc
        if (!aresetn) begin
            wptr <= '0;
        end else begin
            if (wr_en && !full) begin
                mem[wptr] <= wr_data;
                wptr      <= wptr + 1'b1;
            end
        end
    end

    // read part
    always_ff @(posedge aclk or negedge aresetn) begin : read_proc
        if (!aresetn) begin
            rptr <= '0;
        end else begin
            if (rd_en && !empty) begin
                rptr <= rptr + 1'b1;
            end
        end
    end

    //count
    //had to make a separate block cause it didnt worked other wise when mixed with write and read ff block.
    always_ff @(posedge aclk or negedge aresetn) begin : count_proc
        if (!aresetn) begin
            count <= '0;
        end else begin
            unique case ({(wr_en && !full), (rd_en && !empty)})
                2'b10: count <= count + 1'b1; // write only
                2'b01: count <= count - 1'b1; // read only
                default: /* no change */ ;
            endcase
        end
    end

    //from here on we add a signal that that makes the fifo bypass and connect axis slace to axis master directly
    //this process be called cut through switching
    //this shall only be turned on when the fifo is empty
    //and when packet parser has completed its parsing //
    // portion will be added later on when the packet parser is developed

endmodule
